package com.piotrwittig.plan_pm

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

data class LectureItem(val name: String, val start: String, val end: String, val location: String)

class ScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("schedule_data", "[]") ?: "[]"

        val lectures = mutableListOf<LectureItem>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                lectures.add(
                    LectureItem(
                        name = obj.optString("name", ""),
                        start = obj.optString("start", ""),
                        end = obj.optString("end", ""),
                        location = obj.optString("location", "")
                    )
                )
            }
        } catch (_: Exception) {}

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_schedule)
            bindWidget(views, lectures)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindWidget(views: RemoteViews, lectures: List<LectureItem>) {
        if (lectures.isEmpty()) {
            views.setViewVisibility(R.id.widget_card_1, View.GONE)
            views.setViewVisibility(R.id.widget_card_2, View.GONE)
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            return
        }

        views.setViewVisibility(R.id.widget_empty, View.GONE)

        bindCard(views, lectures, 0,
            cardId = R.id.widget_card_1,
            nameId = R.id.widget_name_1,
            timeId = R.id.widget_time_1,
            locationId = R.id.widget_location_1)

        bindCard(views, lectures, 1,
            cardId = R.id.widget_card_2,
            nameId = R.id.widget_name_2,
            timeId = R.id.widget_time_2,
            locationId = R.id.widget_location_2)
    }

    private fun bindCard(
        views: RemoteViews,
        lectures: List<LectureItem>,
        idx: Int,
        cardId: Int,
        nameId: Int,
        timeId: Int,
        locationId: Int
    ) {
        if (idx >= lectures.size) {
            views.setViewVisibility(cardId, View.GONE)
            return
        }

        val lecture = lectures[idx]
        views.setViewVisibility(cardId, View.VISIBLE)
        views.setTextViewText(nameId, lecture.name)
        views.setTextViewText(timeId, "${lecture.start} – ${lecture.end}")

        if (lecture.location.isNotEmpty()) {
            views.setTextViewText(locationId, lecture.location)
            views.setViewVisibility(locationId, View.VISIBLE)
        } else {
            views.setViewVisibility(locationId, View.GONE)
        }
    }
}
