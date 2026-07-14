package com.piotrwittig.plan_pm

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

data class LectureItem(
    val name: String,
    val start: String,
    val end: String,
    val location: String,
    val date: String,
    // Rector-hours / canceled state. `rector` is the state key (empty for an
    // ordinary lecture); `badge` is the localized label to show in the pill.
    val rector: String = "",
    val badge: String = ""
) {
    val isRector: Boolean get() = rector.isNotEmpty()
}

open class ScheduleWidgetProvider : AppWidgetProvider() {

    private companion object {
        const val MAX_CARDS = 7  // must match the number of card slots in widget_schedule.xml
        // Must stay in sync with dimens.xml values used in widget_schedule.xml.
        const val VERTICAL_PADDING_DP = 28  // widget_padding (14dp) × 2
        const val CARD_HEIGHT_DP      = 62  // widget_card_height (EXACT, must match dimens.xml)
        const val CARD_GAP_DP         = 5   // widget_card_gap
        const val MIN_PAD_DP          = 2   // floor for the symmetric inset
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
                        location = obj.optString("location", ""),
                        date = obj.optString("date", ""),
                        rector = obj.optString("rector", ""),
                        badge = obj.optString("badge", "")
                    )
                )
            }
        } catch (_: Exception) {}
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).format(Date())
        // Old payloads did not carry a date and could display yesterday's
        // schedule after midnight. Treat missing/mismatched dates as stale.
        return lectures.filter { it.date == today }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        lectures: List<LectureItem>
    ) {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val heightDp = widgetHeightDp(options)
        val cardCount = resolveCardCount(heightDp)

        val visible = filterRelevant(lectures, cardCount)

        val views = RemoteViews(context.packageName, R.layout.widget_schedule)
        bindWidget(context, views, visible, cardCount)
        val openApp = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("planpm://schedule")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            openApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_box, pendingIntent)
        applyBoxPadding(context, views, heightDp, visible.size)
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    // Centers the cards vertically and frames them with an equal inset on all four
    // sides: the leftover vertical space (height − card stack) is split top/bottom,
    // and that same value is reused left/right. shownCount must be the number of cards
    // actually rendered (fewer when there aren't enough lectures) so partial lists
    // are centered and framed too.
    private fun applyBoxPadding(context: Context, views: RemoteViews, heightDp: Int, shownCount: Int) {
        if (shownCount <= 0) return  // empty state keeps the layout's default padding
        val cardStackDp = shownCount * CARD_HEIGHT_DP + (shownCount - 1) * CARD_GAP_DP
        val padDp = ((heightDp - cardStackDp) / 2).coerceAtLeast(MIN_PAD_DP)
        val padPx = (padDp * context.resources.displayMetrics.density).toInt()
        views.setViewPadding(R.id.widget_box, padPx, padPx, padPx, padPx)
    }

    private fun widgetHeightDp(options: Bundle): Int {
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return when {
            maxHeight > 0 -> maxHeight
            minHeight > 0 -> minHeight
            else -> VERTICAL_PADDING_DP + CARD_HEIGHT_DP  // default → 1 card
        }
    }

    // Returns how many cards fit: n = floor((height - padding + gap) / (cardHeight + gap)).
    // Cards are fixed-height and top-aligned (like iOS) — leftover space stays empty
    // rather than stretching the cards to fill it.
    private fun cardCountForHeight(heightDp: Int): Int {
        val available = heightDp - VERTICAL_PADDING_DP + CARD_GAP_DP
        val cardUnit = CARD_HEIGHT_DP + CARD_GAP_DP
        return (available / cardUnit).coerceIn(1, MAX_CARDS)
    }

    // Default card count: height-based with a comfortable padding reserve.
    // Subclasses may override (the small widget packs more cards into the same footprint).
    protected open fun resolveCardCount(heightDp: Int): Int = cardCountForHeight(heightDp)

    // Max cards whose stack fits the height while still leaving the minimum inset
    // (2 × MIN_PAD_DP) that applyBoxPadding will apply, so the last card is never
    // clipped below the widget edge.
    protected fun maxCardsThatFit(heightDp: Int): Int =
        ((heightDp - 2 * MIN_PAD_DP + CARD_GAP_DP) / (CARD_HEIGHT_DP + CARD_GAP_DP)).coerceIn(1, MAX_CARDS)

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

    private fun bindWidget(context: Context, views: RemoteViews, lectures: List<LectureItem>, cardCount: Int) {
        val slots = listOf(
            CardSlot(R.id.widget_card_1, R.id.widget_name_1, R.id.widget_time_1, R.id.widget_location_1, R.id.widget_progress_1, R.drawable.widget_card_grad_0),
            CardSlot(R.id.widget_card_2, R.id.widget_name_2, R.id.widget_time_2, R.id.widget_location_2, R.id.widget_progress_2, R.drawable.widget_card_grad_1),
            CardSlot(R.id.widget_card_3, R.id.widget_name_3, R.id.widget_time_3, R.id.widget_location_3, R.id.widget_progress_3, R.drawable.widget_card_grad_2),
            CardSlot(R.id.widget_card_4, R.id.widget_name_4, R.id.widget_time_4, R.id.widget_location_4, R.id.widget_progress_4, R.drawable.widget_card_grad_3),
            CardSlot(R.id.widget_card_5, R.id.widget_name_5, R.id.widget_time_5, R.id.widget_location_5, R.id.widget_progress_5, R.drawable.widget_card_grad_4),
            CardSlot(R.id.widget_card_6, R.id.widget_name_6, R.id.widget_time_6, R.id.widget_location_6, R.id.widget_progress_6, R.drawable.widget_card_grad_5),
            CardSlot(R.id.widget_card_7, R.id.widget_name_7, R.id.widget_time_7, R.id.widget_location_7, R.id.widget_progress_7, R.drawable.widget_card_grad_6),
        )

        if (lectures.isEmpty()) {
            slots.forEach { views.setViewVisibility(it.cardId, View.GONE) }
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            views.setTextViewText(
                R.id.widget_empty,
                prefs.getString("widget_empty", context.getString(R.string.widget_empty))
            )
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            return
        }

        views.setViewVisibility(R.id.widget_empty, View.GONE)

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
                gradientRes = slot.gradientRes)
        }
    }

    private data class CardSlot(
        val cardId: Int,
        val nameId: Int,
        val timeId: Int,
        val locationId: Int,
        val progressId: Int,
        val gradientRes: Int
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
        gradientRes: Int
    ) {
        if (idx >= lectures.size) {
            views.setViewVisibility(cardId, View.GONE)
            return
        }

        val lecture = lectures[idx]
        views.setViewVisibility(cardId, View.VISIBLE)
        // Strike through the time and room too (alongside the title) for rector
        // hours / canceled lectures, matching the in-app card.
        val timeText = "${lecture.start} – ${lecture.end}"
        views.setTextViewText(timeId, if (lecture.isRector) strikeThrough(timeText) else timeText)

        if (lecture.location.isNotEmpty()) {
            views.setTextViewText(
                locationId,
                if (lecture.isRector) strikeThrough(lecture.location) else lecture.location
            )
            views.setViewVisibility(locationId, View.VISIBLE)
        } else {
            views.setViewVisibility(locationId, View.GONE)
        }

        // RemoteViews recycle across updates, so both branches must explicitly
        // set the background, title icon and styling to avoid stale state.
        // Rector hours / canceled: grey card + a compact leading warning icon on
        // the (struck-through) title — no extra row, keeping the card height.
        if (lecture.isRector) {
            views.setInt(cardId, "setBackgroundResource", R.drawable.widget_card_rector)
            views.setTextViewText(nameId, strikeThrough(lecture.name))
            views.setTextViewCompoundDrawablesRelative(nameId, R.drawable.ic_widget_warning, 0, 0, 0)
            // No live progress bar for rector / canceled lectures (matches the app).
            views.setViewVisibility(progressId, View.GONE)
            return
        }

        views.setInt(cardId, "setBackgroundResource", gradientRes)
        views.setTextViewText(nameId, lecture.name)
        views.setTextViewCompoundDrawablesRelative(nameId, 0, 0, 0, 0)

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

    private fun strikeThrough(text: String): SpannableString =
        SpannableString(text).apply {
            setSpan(StrikethroughSpan(), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
}

// Three fixed-size, non-resizable widgets. They differ only by their footprint
// (provider-info XML); the card count adapts to each one's height via the base
// class, so the white box is filled without clipping the last card.

/** Small widget — packs up to 3 cards into its (unchanged) footprint, capped so the
 *  last card is never clipped if the launcher gives it less room. */
class ScheduleWidgetSmall : ScheduleWidgetProvider() {
    override fun resolveCardCount(heightDp: Int): Int = minOf(3, maxCardsThatFit(heightDp))
}

/** Medium widget — packs up to 5 cards into its (unchanged) footprint, capped so the
 *  last card is never clipped if the launcher gives it less room. */
class ScheduleWidgetMedium : ScheduleWidgetProvider() {
    override fun resolveCardCount(heightDp: Int): Int = minOf(5, maxCardsThatFit(heightDp))
}

/** Large widget — full screen width; packs as many cards as physically fit (up to 7). */
class ScheduleWidgetLarge : ScheduleWidgetProvider() {
    override fun resolveCardCount(heightDp: Int): Int = maxCardsThatFit(heightDp)
}
