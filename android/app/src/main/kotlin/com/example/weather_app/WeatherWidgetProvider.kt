package com.example.weather_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WeatherWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d("WeatherWidget", "onUpdate called with ${appWidgetIds.size} widgets")
        
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.weather_widget)
            
            val prefs = HomeWidgetPlugin.getData(context)
            val city = prefs.getString("widget_city", "no city") ?: "no city"
            val temp = prefs.getString("widget_temp", "no temp") ?: "no temp"
            val rain = prefs.getString("widget_rain", "") ?: ""

            Log.d("WeatherWidget", "city=$city temp=$temp rain=$rain")

            views.setTextViewText(R.id.widget_city, city)
            views.setTextViewText(R.id.widget_temp, temp)
            views.setTextViewText(R.id.widget_rain, rain)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}