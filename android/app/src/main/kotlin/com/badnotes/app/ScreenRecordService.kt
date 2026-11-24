package com.badnotes.app

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/// Records the screen into an mp4, for the lag build's Record button: some
/// lag only shows in a video. Android needs a foreground service for this,
/// started before the recording is.
class ScreenRecordService : Service() {
    companion object {
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_DATA = "data"
        const val EXTRA_PATH = "path"
        private const val CHANNEL = "screen_record"

        /// Called with the file once a recording has stopped (null if it failed).
        var onStopped: ((String?) -> Unit)? = null
        var onStarted: ((Boolean) -> Unit)? = null
        var running = false
            private set
        private var instance: ScreenRecordService? = null

        fun stop() {
            instance?.finish() ?: onStopped?.invoke(null)
        }
    }

    private var projection: MediaProjection? = null
    private var display: VirtualDisplay? = null
    private var recorder: MediaRecorder? = null
    private var path: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this
        startInForeground()
        val started = try {
            begin(intent!!)
            true
        } catch (e: Exception) {
            cleanUp()
            false
        }
        running = started
        onStarted?.invoke(started)
        onStarted = null
        if (!started) stopSelf()
        return START_NOT_STICKY
    }

    private fun startInForeground() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, "Screen recording", NotificationManager.IMPORTANCE_LOW)
            )
        }
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL)
        } else {
            Notification.Builder(this)
        }
        val notification = builder
            .setContentTitle("BadNotes is recording the screen")
            .setContentText("For a lag report. Tap Stop in the app to end it.")
            .setSmallIcon(android.R.drawable.presence_video_online)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(1, notification)
        }
    }

    private fun begin(intent: Intent) {
        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
        val data: Intent = readData(intent) ?: throw IllegalStateException("no permission data")
        path = intent.getStringExtra(EXTRA_PATH)!!

        val metrics = resources.displayMetrics
        // at most 1280 on the long side: small enough to upload over mobile
        // data, sharp enough to see the ink
        val scale = minOf(1.0, 1280.0 / maxOf(metrics.widthPixels, metrics.heightPixels))
        val width = (metrics.widthPixels * scale).toInt() / 2 * 2
        val height = (metrics.heightPixels * scale).toInt() / 2 * 2

        @Suppress("DEPRECATION")
        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(this) else MediaRecorder()
        recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        recorder.setVideoSize(width, height)
        // 60 frames a second, so a dropped frame shows
        recorder.setVideoFrameRate(60)
        recorder.setVideoEncodingBitRate(4_000_000)
        recorder.setOutputFile(path)
        recorder.prepare()
        this.recorder = recorder

        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val projection: MediaProjection = manager.getMediaProjection(resultCode, data)
            ?: throw IllegalStateException("no projection")
        this.projection = projection
        // needed before a virtual display since Android 14
        projection.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                // stopped from the system (the status bar chip)
                Handler(Looper.getMainLooper()).post { finish() }
            }
        }, Handler(Looper.getMainLooper()))
        display = projection.createVirtualDisplay(
            "BadNotes recording",
            width,
            height,
            metrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            recorder.surface,
            null,
            null,
        )
        recorder.start()
    }

    private fun readData(intent: Intent): Intent? {
        if (Build.VERSION.SDK_INT >= 33) {
            return intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
        }
        @Suppress("DEPRECATION")
        return intent.getParcelableExtra(EXTRA_DATA)
    }

    /// Stops recording and hands the file to [onStopped].
    /// MediaRecorder.stop() writes out the mp4 and took ~0.8 s; on the main
    /// thread (which Flutter's UI now shares) that froze the app, so it runs
    /// on a thread of its own and only the hand-off comes back to main.
    @Suppress("DEPRECATION")
    fun finish() {
        if (!running) return
        running = false
        val recorder = this.recorder
        val display = this.display
        val projection = this.projection
        val path = this.path
        this.recorder = null
        this.display = null
        this.projection = null
        Thread {
            var ok = true
            try {
                recorder?.stop()
            } catch (e: Exception) {
                // too short to have any frames
                ok = false
            }
            release(recorder, display, projection)
            Handler(Looper.getMainLooper()).post {
                onStopped?.invoke(if (ok) path else null)
                onStopped = null
                stopForeground(true)
                stopSelf()
            }
        }.start()
    }

    private fun cleanUp() {
        release(recorder, display, projection)
        recorder = null
        display = null
        projection = null
    }

    private fun release(recorder: MediaRecorder?, display: VirtualDisplay?, projection: MediaProjection?) {
        try { recorder?.release() } catch (e: Exception) {}
        try { display?.release() } catch (e: Exception) {}
        try { projection?.stop() } catch (e: Exception) {}
    }

    override fun onDestroy() {
        if (running) finish()
        instance = null
        super.onDestroy()
    }
}
