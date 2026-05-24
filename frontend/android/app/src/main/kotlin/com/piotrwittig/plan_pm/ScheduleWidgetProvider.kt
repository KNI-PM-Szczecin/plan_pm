package com.piotrwittig.plan_pm

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar
import kotlin.math.roundToInt

data class LectureItem(val name: String, val start: String, val end: String, val location: String)

class ScheduleWidgetProvider : AppWidgetProvider() {

    private companion object {
        const val MAX_CARDS = 5
        const val DEFAULT_WIDGET_HEIGHT_DP = 200
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val lectures = readLectures(context)

        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId, lectures)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        val lectures = readLectures(context)
        updateWidget(context, appWidgetManager, appWidgetId, lectures)
    }

    private fun readLectures(context: Context): List<LectureItem> {
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
        return lectures
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        lectures: List<LectureItem>
    ) {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val heightDp = widgetHeightDp(options)
        val cardsFit = cardsThatFit(context, heightDp)

        val visible = filterRelevant(lectures, cardsFit)

        val views = RemoteViews(context.packageName, R.layout.widget_schedule)
        bindWidget(views, visible, cardsFit)
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun widgetHeightDp(options: Bundle): Int {
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return when {
            maxHeight > 0 -> maxHeight
            minHeight > 0 -> minHeight
            else -> DEFAULT_WIDGET_HEIGHT_DP
        }
    }

    private fun cardsThatFit(context: Context, heightDp: Int): Int {
        val verticalPaddingDp = context.dimensionDp(R.dimen.widget_padding) * 2
        val cardMinHeightDp = context.dimensionDp(R.dimen.widget_card_min_height)
        val cardGapDp = context.dimensionDp(R.dimen.widget_card_gap)

        val availableForCards = heightDp - verticalPaddingDp
        val cardAndGap = cardMinHeightDp + cardGapDp
        val count = (availableForCards + cardGapDp) / cardAndGap

        return count.coerceIn(1, MAX_CARDS)
    }

    private fun filterRelevant(lectures: List<LectureItem>, cardsFit: Int): List<LectureItem> {
        if (lectures.size <= cardsFit) return lectures
        val nowMinutes = currentMinutesOfDay()
        val firstCurrentOrUpcoming = lectures.indexOfFirst { endMinutes(it.end) >= nowMinutes }
        val anchor = if (firstCurrentOrUpcoming >= 0) firstCurrentOrUpcoming else lectures.lastIndex
        val lastStart = lectures.size - cardsFit
        val start = anchor.coerceIn(0, lastStart)

        return lectures.drop(start).take(cardsFit)
    }

    private fun currentMinutesOfDay(): Int {
        val c = Calendar.getInstance()
        return c.get(Calendar.HOUR_OF_DAY) * 60 + c.get(Calendar.MINUTE)
    }

    private fun endMinutes(time: String): Int {
        val parts = time.split(":")
        if (parts.size < 2) return Int.MAX_VALUE
        val h = parts[0].toIntOrNull() ?: return Int.MAX_VALUE
        val m = parts[1].toIntOrNull() ?: return Int.MAX_VALUE
        return h * 60 + m
    }

    private fun bindWidget(views: RemoteViews, lectures: List<LectureItem>, cardsFit: Int) {
        val cardIds = listOf(
            R.id.widget_card_1, R.id.widget_card_2, R.id.widget_card_3,
            R.id.widget_card_4, R.id.widget_card_5
        )

        if (lectures.isEmpty()) {
            cardIds.forEach { views.setViewVisibility(it, View.GONE) }
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            return
        }

        views.setViewVisibility(R.id.widget_empty, View.GONE)

        val slots = listOf(
            CardSlot(R.id.widget_card_1, R.id.widget_name_1, R.id.widget_time_1, R.id.widget_location_1, R.id.widget_progress_1),
            CardSlot(R.id.widget_card_2, R.id.widget_name_2, R.id.widget_time_2, R.id.widget_location_2, R.id.widget_progress_2),
            CardSlot(R.id.widget_card_3, R.id.widget_name_3, R.id.widget_time_3, R.id.widget_location_3, R.id.widget_progress_3),
            CardSlot(R.id.widget_card_4, R.id.widget_name_4, R.id.widget_time_4, R.id.widget_location_4, R.id.widget_progress_4),
            CardSlot(R.id.widget_card_5, R.id.widget_name_5, R.id.widget_time_5, R.id.widget_location_5, R.id.widget_progress_5),
        )

        for ((idx, slot) in slots.withIndex()) {
            if (idx >= cardsFit) {
                views.setViewVisibility(slot.cardId, View.GONE)
                continue
            }
            bindCard(views, lectures, idx,
                cardId = slot.cardId,
                nameId = slot.nameId,
                timeId = slot.timeId,
                locationId = slot.locationId,
                progressId = slot.progressId)
        }
    }

    private data class CardSlot(
        val cardId: Int,
        val nameId: Int,
        val timeId: Int,
        val locationId: Int,
        val progressId: Int
    )

    private fun bindCard(
        views: RemoteViews,
        lectures: List<LectureItem>,
        idx: Int,
        cardId: Int,
        nameId: Int,
        timeId: Int,
        locationId: Int,
        progressId: Int
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

        val startMin = endMinutes(lecture.start)
        val endMin = endMinutes(lecture.end)
        val nowMin = currentMinutesOfDay()
        if (nowMin in startMin..endMin && endMin > startMin) {
            val progress = ((nowMin - startMin) * 100) / (endMin - startMin)
            views.setProgressBar(progressId, 100, progress, false)
            views.setViewVisibility(progressId, View.VISIBLE)
        } else {
            views.setViewVisibility(progressId, View.INVISIBLE)
        }
    }

    private fun Context.dimensionDp(resId: Int): Int =
        (resources.getDimension(resId) / resources.displayMetrics.density).roundToInt()
}
