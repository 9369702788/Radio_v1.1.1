package com.worldradio.app

import android.app.PictureInPictureParams
import android.content.Intent
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.worldradio.app/widget"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    val name = call.argument<String>("name") ?: "World Radio"
                    val country = call.argument<String>("country") ?: ""
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    RadioWidgetProvider.updateAllWidgets(applicationContext, name, country, isPlaying)
                    result.success(true)
                }
                "enterPip" -> {
                    enterPipMode()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(16, 9))
                    .build()
                enterPictureInPictureMode(params)
            } catch (_: Exception) {}
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Automatically enter Floating PiP when user presses home while listening to radio!
        if (RadioWidgetProvider.isPlaying && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            enterPipMode()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getStringExtra("widget_action") == "toggle_play") {
            methodChannel?.invokeMethod("onWidgetTogglePlay", null)
        }
    }
}
