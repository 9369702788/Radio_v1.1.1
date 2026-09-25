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
            val views = RemoteViews(context.packageName, R.layout.radio_widget)
            
            // Play/Pause Intent
            val playIntent = Intent(context, MainActivity::class.java).apply { action = "com.worldradio.app.PLAY_PAUSE" }
            val playPendingIntent = PendingIntent.getActivity(context, 0, playIntent, PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_play_pause, playPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
