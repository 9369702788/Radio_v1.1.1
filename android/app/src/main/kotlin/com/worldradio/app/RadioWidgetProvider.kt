package com.worldradio.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class RadioWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val ACTION_PLAY_PAUSE = "com.worldradio.app.ACTION_WIDGET_PLAY_PAUSE"

        var currentStationName: String = "World Radio"
        var currentCountry: String = "انقر للتشغيل والاستماع"
        var isPlaying: Boolean = false

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.radio_widget)

            views.setTextViewText(R.id.widget_station_name, currentStationName)
            views.setTextViewText(R.id.widget_station_desc, currentCountry)
            views.setImageViewResource(
                R.id.widget_play_button,
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            )

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context, 0, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent)

            val playPauseIntent = Intent(context, RadioWidgetProvider::class.java).apply {
                action = ACTION_PLAY_PAUSE
            }
            val playPausePendingIntent = PendingIntent.getBroadcast(
                context, 1, playPauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_play_button, playPausePendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context, name: String, country: String, playing: Boolean) {
            currentStationName = name
            currentCountry = country
            isPlaying = playing

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, RadioWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_PLAY_PAUSE) {
            val mainIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("widget_action", "toggle_play")
            }
            context.startActivity(mainIntent)
        }
    }
}
