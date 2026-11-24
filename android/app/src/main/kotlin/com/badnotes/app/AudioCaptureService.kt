package com.badnotes.app

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/// Records a note's sound with its writing: what plays on the device (a
/// video, a lecture), the microphone, or both mixed, into AAC in an .m4a.
/// The device's sound needs Android 10 and the screen-capture permission,
/// and Android wants a foreground service for it.
class AudioCaptureService : Service() {
    companion object {
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_DATA = "data"
        const val EXTRA_PATH = "path"
        const val EXTRA_MIC = "mic"
        private const val CHANNEL = "note_recording"
        private const val RATE = 44100

        var onStarted: ((String?) -> Unit)? = null
        var onStopped: (() -> Unit)? = null
        var running = false
            private set
        private var instance: AudioCaptureService? = null

        fun stop() {
            instance?.finish() ?: onStopped?.invoke()
        }
    }

    private var projection: MediaProjection? = null
    private var device: AudioRecord? = null
    private var mic: AudioRecord? = null
    @Volatile private var recording = false
    private var worker: Thread? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this
        val withMic = intent?.getBooleanExtra(EXTRA_MIC, false) ?: false
        startInForeground(withMic)
        val problem = try {
            begin(intent!!, withMic)
            null
        } catch (e: Exception) {
            cleanUp()
            e.message ?: "Could not record the device's sound"
        }
        running = problem == null
        onStarted?.invoke(problem)
        onStarted = null
        if (problem != null) stopSelf()
        return START_NOT_STICKY
    }

    private fun startInForeground(withMic: Boolean) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, "Note recording", NotificationManager.IMPORTANCE_LOW)
            )
        }
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL)
        } else {
            Notification.Builder(this)
        }
        val notification = builder
            .setContentTitle("BadNotes is recording")
            .setContentText("Your writing and sound. Stop it in the note.")
            .setSmallIcon(android.R.drawable.presence_audio_online)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            var type = ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            if (withMic) type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            startForeground(2, notification, type)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(2, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(2, notification)
        }
    }

    @SuppressLint("MissingPermission")
    private fun begin(intent: Intent, withMic: Boolean) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw IllegalStateException("Recording the device's sound needs Android 10 or later")
        }
        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
        val data = readData(intent) ?: throw IllegalStateException("No permission to capture")
        val path = intent.getStringExtra(EXTRA_PATH) ?: throw IllegalStateException("No file")

        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val projection = manager.getMediaProjection(resultCode, data)
            ?: throw IllegalStateException("No permission to capture")
        this.projection = projection
        projection.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                // stopped from the system (the status bar)
                Handler(Looper.getMainLooper()).post { finish() }
            }
        }, Handler(Looper.getMainLooper()))

        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(RATE)
            .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
            .build()
        val buffer = maxOf(
            AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT),
            RATE / 5 * 2,
        ) * 2
        val capture = AudioPlaybackCaptureConfiguration.Builder(projection)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            .build()
        val device = AudioRecord.Builder()
            .setAudioFormat(format)
            .setBufferSizeInBytes(buffer)
            .setAudioPlaybackCaptureConfig(capture)
            .build()
        this.device = device
        if (withMic) {
            mic = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                buffer,
            )
        }

        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        val aac = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, RATE, 1)
        aac.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
        aac.setInteger(MediaFormat.KEY_BIT_RATE, 128_000)
        aac.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
        encoder.configure(aac, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        device.startRecording()
        mic?.startRecording()
        encoder.start()
        recording = true
        worker = Thread { encode(device, mic, encoder, muxer) }.also { it.start() }
    }

    /// Reads both sources a block at a time, mixes them, and encodes.
    private fun encode(device: AudioRecord, mic: AudioRecord?, encoder: MediaCodec, muxer: MediaMuxer) {
        val block = 2048
        val a = ShortArray(block)
        val b = ShortArray(block)
        val info = MediaCodec.BufferInfo()
        var track = -1
        var samples = 0L
        var ended = false

        fun drain(endOfStream: Boolean) {
            while (true) {
                val out = encoder.dequeueOutputBuffer(info, if (endOfStream) 10_000 else 0)
                when {
                    out == MediaCodec.INFO_TRY_AGAIN_LATER -> if (!endOfStream) return
                    out == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        track = muxer.addTrack(encoder.outputFormat)
                        muxer.start()
                    }
                    out >= 0 -> {
                        val data = encoder.getOutputBuffer(out)!!
                        if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) info.size = 0
                        if (info.size > 0 && track >= 0) {
                            data.position(info.offset)
                            data.limit(info.offset + info.size)
                            muxer.writeSampleData(track, data, info)
                        }
                        encoder.releaseOutputBuffer(out, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
                    }
                }
            }
        }

        try {
            while (!ended) {
                val stopping = !recording
                val read = device.read(a, 0, block)
                val n = if (read > 0) read else 0
                if (mic != null) {
                    val m = mic.read(b, 0, n.coerceAtLeast(1))
                    for (i in 0 until minOf(n, maxOf(m, 0))) {
                        a[i] = (a[i] + b[i]).coerceIn(-32768, 32767).toShort()
                    }
                }
                val input = encoder.dequeueInputBuffer(10_000)
                if (input >= 0) {
                    val buffer = encoder.getInputBuffer(input)!!
                    buffer.clear()
                    for (i in 0 until n) buffer.putShort(a[i])
                    val time = samples * 1_000_000L / RATE
                    samples += n
                    if (stopping) {
                        encoder.queueInputBuffer(input, 0, n * 2, time, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        ended = true
                    } else {
                        encoder.queueInputBuffer(input, 0, n * 2, time, 0)
                    }
                }
                drain(ended)
            }
        } catch (e: Exception) {
            // whatever was written so far is kept
        } finally {
            try { encoder.stop() } catch (e: Exception) {}
            encoder.release()
            try { muxer.stop() } catch (e: Exception) {}
            muxer.release()
        }
    }

    private fun readData(intent: Intent): Intent? {
        if (Build.VERSION.SDK_INT >= 33) {
            return intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
        }
        @Suppress("DEPRECATION")
        return intent.getParcelableExtra(EXTRA_DATA)
    }

    /// Stops recording, finishes the file, and tells [onStopped].
    @Suppress("DEPRECATION")
    fun finish() {
        if (!running) return
        running = false
        recording = false
        try { worker?.join(3000) } catch (e: Exception) {}
        cleanUp()
        onStopped?.invoke()
        onStopped = null
        stopForeground(true)
        stopSelf()
    }

    private fun cleanUp() {
        recording = false
        try { device?.stop() } catch (e: Exception) {}
        try { device?.release() } catch (e: Exception) {}
        try { mic?.stop() } catch (e: Exception) {}
        try { mic?.release() } catch (e: Exception) {}
        try { projection?.stop() } catch (e: Exception) {}
        device = null
        mic = null
        projection = null
    }

    override fun onDestroy() {
        if (running) finish()
        instance = null
        super.onDestroy()
    }
}
