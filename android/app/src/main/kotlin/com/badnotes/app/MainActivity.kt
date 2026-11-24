package com.badnotes.app

import android.os.Build
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.app.Activity
import android.media.projection.MediaProjectionManager
import java.io.File

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "badnotes/screen")
            .setMethodCallHandler { call, result ->
                if (call.method != "openCasting") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Settings.ACTION_CAST_SETTINGS))
                    result.success(true)
                } catch (e: Exception) {
                    // not every device has this screen
                    result.success(false)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "badnotes/record")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> startRecording(result)
                    "stop" -> {
                        if (!ScreenRecordService.running) {
                            result.success(null)
                        } else {
                            ScreenRecordService.onStopped = { path -> runOnUiThread { result.success(path) } }
                            ScreenRecordService.stop()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "badnotes/device_audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> startDeviceAudio(
                        call.argument<String>("path") ?: "",
                        call.argument<Boolean>("mic") ?: false,
                        result,
                    )
                    "stop" -> {
                        if (!AudioCaptureService.running) {
                            result.success(null)
                        } else {
                            AudioCaptureService.onStopped = { runOnUiThread { result.success(null) } }
                            AudioCaptureService.stop()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private var audioResult: MethodChannel.Result? = null
    private var audioPath = ""
    private var audioMic = false

    /// A note's recording with the device's sound: asks for the screen
    /// capture permission, then [AudioCaptureService] records. Answers true
    /// once it records, false if the permission was refused.
    private fun startDeviceAudio(path: String, mic: Boolean, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported", "Recording the device's sound needs Android 10 or later", null)
            return
        }
        if (AudioCaptureService.running || audioResult != null || path.isEmpty()) {
            result.success(false)
            return
        }
        File(path).parentFile?.mkdirs()
        audioResult = result
        audioPath = path
        audioMic = mic
        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        @Suppress("DEPRECATION")
        startActivityForResult(manager.createScreenCaptureIntent(), AUDIO_REQUEST)
    }

    private fun onDeviceAudioAllowed(resultCode: Int, data: Intent?) {
        val result = audioResult ?: return
        audioResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(false)
            return
        }
        AudioCaptureService.onStarted = { problem ->
            runOnUiThread {
                if (problem == null) result.success(true)
                else result.error("failed", problem, null)
            }
        }
        val intent = Intent(this, AudioCaptureService::class.java)
            .putExtra(AudioCaptureService.EXTRA_RESULT_CODE, resultCode)
            .putExtra(AudioCaptureService.EXTRA_DATA, data)
            .putExtra(AudioCaptureService.EXTRA_PATH, audioPath)
            .putExtra(AudioCaptureService.EXTRA_MIC, audioMic)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private var recordResult: MethodChannel.Result? = null

    /// Asks Android to let the app record the screen (the lag build's Record
    /// button). Answers true once recording has started.
    private fun startRecording(result: MethodChannel.Result) {
        if (ScreenRecordService.running || recordResult != null) {
            result.success(false)
            return
        }
        recordResult = result
        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        @Suppress("DEPRECATION")
        startActivityForResult(manager.createScreenCaptureIntent(), RECORD_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == AUDIO_REQUEST) {
            onDeviceAudioAllowed(resultCode, data)
            return
        }
        if (requestCode != RECORD_REQUEST) return
        val result = recordResult ?: return
        recordResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(false)
            return
        }
        val file = File(cacheDir, "lag-recording-${System.currentTimeMillis()}.mp4")
        ScreenRecordService.onStarted = { ok -> runOnUiThread { result.success(ok) } }
        val intent = Intent(this, ScreenRecordService::class.java)
            .putExtra(ScreenRecordService.EXTRA_RESULT_CODE, resultCode)
            .putExtra(ScreenRecordService.EXTRA_DATA, data)
            .putExtra(ScreenRecordService.EXTRA_PATH, file.absolutePath)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    companion object {
        private const val RECORD_REQUEST = 4711
        private const val AUDIO_REQUEST = 4712
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
            this.finish()
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)

        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightNavigationBars = true

        requestHighestRefreshRate()
    }

    /// Ask for the display's fastest mode (90/120 Hz) so writing and
    /// scrolling are smoother. Android otherwise often keeps apps at 60 Hz.
    private fun requestHighestRefreshRate() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            @Suppress("DEPRECATION")
            val display = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) display else windowManager.defaultDisplay)
                ?: return
            val current = display.mode
            val best = display.supportedModes
                .filter { it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight }
                .maxByOrNull { it.refreshRate } ?: return
            val params = window.attributes
            params.preferredDisplayModeId = best.modeId
            window.attributes = params
        } catch (e: Exception) {
            // keep the default refresh rate
        }
    }
}
