package com.worldradio.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Rational
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.worldradio.app/widget"
    private var methodChannel: MethodChannel? = null
    private val NOTIFICATION_CHANNEL_ID = "world_radio_playback_channel"
    private val NOTIFICATION_ID = 101

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
                    showLockScreenNotification(name, country, isPlaying)
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

    private fun showLockScreenNotification(title: String, subtitle: String, isPlaying: Boolean) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "World Radio Live Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows live radio controls on lock screen"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val openIntent = Intent(this, MainActivity::class.java)
        val openPending = PendingIntent.getActivity(this, 0, openIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val toggleIntent = Intent(this, RadioWidgetProvider::class.java).apply {
            action = RadioWidgetProvider.ACTION_PLAY_PAUSE
        }
        val togglePending = PendingIntent.getBroadcast(this, 1, toggleIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setContentIntent(openPending)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(isPlaying)
            .addAction(
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                if (isPlaying) "Pause" else "Play",
                togglePending
            )
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setShowActionsInCompactView(0)
            )
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
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
