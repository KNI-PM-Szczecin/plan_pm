package com.piotrwittig.plan_pm

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar

data class LectureItem(val name: String, val start: String, val end: String, val location: String)

class ScheduleWidgetProvider : AppWidgetProvider() {

    private companion object {
        const val MAX_CARDS = 5
        // Must stay in sync with dimens.xml values used in widget_schedule.xml.
        const val VERTICAL_PADDING_DP = 28  // widget_padding (14dp) × 2
        const val CARD_MIN_HEIGHT_DP  = 67  // widget_card_min_height
        const val CARD_GAP_DP         = 8   // widget_card_gap
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
        val cardCount = cardCountForHeight(heightDp)
        val cardHeightDp = (heightDp - VERTICAL_PADDING_DP - (cardCount - 1) * CARD_GAP_DP) / cardCount

        val visible = filterRelevant(lectures, cardCount)

        val views = RemoteViews(context.packageName, R.layout.widget_schedule)
        bindWidget(views, visible, cardCount, cardHeightDp)
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun widgetHeightDp(options: Bundle): Int {
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return when {
            maxHeight > 0 -> maxHeight
            minHeight > 0 -> minHeight
            else -> VERTICAL_PADDING_DP + CARD_MIN_HEIGHT_DP  // default → 1 card
        }
    }

    // Returns how many cards fit: n = floor((height - padding + gap) / (cardHeight + gap)).
    // Cards use layout_weight so they stretch to fill any remaining space — no clipping.
    private fun cardCountForHeight(heightDp: Int): Int {
        val available = heightDp - VERTICAL_PADDING_DP + CARD_GAP_DP
        val cardUnit = CARD_MIN_HEIGHT_DP + CARD_GAP_DP
        return (available / cardUnit).coerceIn(1, MAX_CARDS)
    }

    private fun filterRelevant(lectures: List<LectureItem>, cardCount: Int): List<LectureItem> {
        if (lectures.size <= cardCount) return lectures
        val nowMinutes = currentMinutesOfDay()
        val firstCurrentOrUpcoming = lectures.indexOfFirst { endMinutes(it.end) >= nowMinutes }
        val anchor = if (firstCurrentOrUpcoming >= 0) firstCurrentOrUpcoming else lectures.lastIndex
        val lastStart = lectures.size - cardCount
        val start = anchor.coerceIn(0, lastStart)
        return lectures.drop(start).take(cardCount)
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

    private fun bindWidget(views: RemoteViews, lectures: List<LectureItem>, cardCount: Int, cardHeightDp: Int) {
        val slots = listOf(
            CardSlot(R.id.widget_card_1, R.id.widget_name_1, R.id.widget_time_1, R.id.widget_location_1, R.id.widget_progress_1),
            CardSlot(R.id.widget_card_2, R.id.widget_name_2, R.id.widget_time_2, R.id.widget_location_2, R.id.widget_progress_2),
            CardSlot(R.id.widget_card_3, R.id.widget_name_3, R.id.widget_time_3, R.id.widget_location_3, R.id.widget_progress_3),
            CardSlot(R.id.widget_card_4, R.id.widget_name_4, R.id.widget_time_4, R.id.widget_location_4, R.id.widget_progress_4),
            CardSlot(R.id.widget_card_5, R.id.widget_name_5, R.id.widget_time_5, R.id.widget_location_5, R.id.widget_progress_5),
        )

        if (lectures.isEmpty()) {
            slots.forEach { views.setViewVisibility(it.cardId, View.GONE) }
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            return
        }

        views.setViewVisibility(R.id.widget_empty, View.GONE)

        val rootGravity = if (cardCount == MAX_CARDS && lectures.size >= MAX_CARDS) {
            Gravity.CENTER_VERTICAL or Gravity.START
        } else {
            Gravity.TOP or Gravity.START
        }
        views.setInt(R.id.widget_root, "setGravity", rootGravity)

        val nameSp = nameFontSp(cardHeightDp)
        val timeSp = timeFontSp(cardHeightDp)

        for ((idx, slot) in slots.withIndex()) {
            if (idx >= cardCount) {
                views.setViewVisibility(slot.cardId, View.GONE)
                continue
            }
            bindCard(views, lectures, idx,
                cardId = slot.cardId,
                nameId = slot.nameId,
                timeId = slot.timeId,
                locationId = slot.locationId,
                progressId = slot.progressId,
                nameSp = nameSp,
                timeSp = timeSp)
        }
    }

    // Scale name font: 14sp at ≤67dp, up to 22sp at ≥130dp.
    private fun nameFontSp(cardHeightDp: Int): Float =
        (14f + (cardHeightDp - CARD_MIN_HEIGHT_DP).coerceAtLeast(0) * 0.12f).coerceAtMost(22f)

    // Scale time/location font: 11sp at ≤67dp, up to 15sp at ≥130dp.
    private fun timeFontSp(cardHeightDp: Int): Float =
        (11f + (cardHeightDp - CARD_MIN_HEIGHT_DP).coerceAtLeast(0) * 0.06f).coerceAtMost(15f)

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
        progressId: Int,
        nameSp: Float,
        timeSp: Float
    ) {
        if (idx >= lectures.size) {
            views.setViewVisibility(cardId, View.GONE)
            return
        }

        val lecture = lectures[idx]
        views.setViewVisibility(cardId, View.VISIBLE)
        views.setTextViewText(nameId, lecture.name)
        views.setTextViewTextSize(nameId, TypedValue.COMPLEX_UNIT_SP, nameSp)
        views.setTextViewText(timeId, "${lecture.start} – ${lecture.end}")
        views.setTextViewTextSize(timeId, TypedValue.COMPLEX_UNIT_SP, timeSp)

        if (lecture.location.isNotEmpty()) {
            views.setTextViewText(locationId, lecture.location)
            views.setTextViewTextSize(locationId, TypedValue.COMPLEX_UNIT_SP, timeSp)
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
}
