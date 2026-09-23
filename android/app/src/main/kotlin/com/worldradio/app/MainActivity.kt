package com.worldradio.app

import android.content.Intent
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
            if (call.method == "updateWidget") {
                val name = call.argument<String>("name") ?: "World Radio"
                val country = call.argument<String>("country") ?: ""
                val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                RadioWidgetProvider.updateAllWidgets(applicationContext, name, country, isPlaying)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getStringExtra("widget_action") == "toggle_play") {
            methodChannel?.invokeMethod("onWidgetTogglePlay", null)
        }
    }
}
