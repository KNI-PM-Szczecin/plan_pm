package com.piotrwittig.plan_pm

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class ScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("flutter.schedule_data", "[]") ?: "[]"

        val lectures = mutableListOf<Triple<String, String, String>>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                lectures.add(
                    Triple(
                        obj.optString("name", ""),
                        obj.optString("start", ""),
                        obj.optString("end", "")
                    )
                )
            }
        } catch (_: Exception) {}

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_schedule)
            val lectureViews = listOf(
                R.id.widget_lecture_1,
                R.id.widget_lecture_2,
                R.id.widget_lecture_3,
                R.id.widget_lecture_4,
            )

            if (lectures.isEmpty()) {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                lectureViews.forEach { views.setViewVisibility(it, View.GONE) }
            } else {
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                lectureViews.forEachIndexed { idx, viewId ->
                    if (idx < lectures.size) {
                        val (name, start, end) = lectures[idx]
                        views.setTextViewText(viewId, "$start–$end  $name")
                        views.setViewVisibility(viewId, View.VISIBLE)
                    } else {
                        views.setViewVisibility(viewId, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
