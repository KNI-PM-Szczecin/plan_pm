package com.piotrwittig.plan_pm

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Paint
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
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

// Single resizable home-screen widget. There is exactly one provider class and
// one <receiver> in the manifest; the number of lecture cards is derived from the
// widget's current height at runtime (see flexCapacity / cardCountForHeight), so the
// same code fills a 1-card sliver or a 10-card full-height widget without subclasses.
// On API 31+ card heights also flex slightly so the stack fills the box exactly.
class ScheduleWidgetProvider : AppWidgetProvider() {

    private companion object {
        const val MAX_CARDS = 10  // must match the number of card slots in widget_schedule.xml
        // Must stay in sync with dimens.xml values used in widget_schedule.xml.
        const val CARD_HEIGHT_DP = 62  // widget_card_height — nominal / fixed-height fallback (pre-API-31)
        const val CARD_GAP_DP    = 5   // widget_card_gap (spacing between cards)
        const val CARD_INSET_DP  = 6   // widget_card_inset (CONSTANT border around the card stack)
        const val CARD_TEXT_PADDING_DP = 14  // card paddingStart/End in widget_schedule.xml
        const val TITLE_TEXT_SP = 14f  // widget_name_* textSize (bold) — used to measure titles
        const val TIME_TEXT_SP = 11f   // widget_time_* / widget_location_* textSize — used to measure the row
        const val RECTOR_ICON_ALLOWANCE_DP = 22  // leading warning icon + drawablePadding on rector titles
        const val TIME_ICON_ALLOWANCE_DP = 20    // clock icon + drawablePadding before the time
        const val ROOM_LEAD_ALLOWANCE_DP = 30    // marginStart + pin icon + drawablePadding before the room
        // On API 31+ card heights flex slightly within [MIN, MAX] so the stack fills the
        // box exactly: cards grow (up to MAX) to swallow a small leftover, or shrink
        // (down to MIN) to squeeze in one more card. MIN must still fit the card content
        // (title + time row + progress bar); MAX keeps cards from looking stretched.
        const val MIN_CARD_DP = 60
        const val MAX_CARD_DP = 74
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

        // API 31+ can flex card heights (setViewLayoutHeight); older devices can't, so
        // they fall back to fixed 62dp cards.
        val flexible = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        val availableDp = heightDp - 2 * CARD_INSET_DP  // vertical space for cards + gaps
        val cardCount = if (flexible) flexCapacity(availableDp) else cardCountForHeight(heightDp)

        val visible = filterRelevant(lectures, cardCount)

        // Height each shown card gets so the stack fills the box: total space split
        // evenly across the actually-visible cards, clamped to [MIN, MAX]. -1 = keep
        // the layout's fixed height (fallback path).
        val cardHeightDp = if (flexible && visible.isNotEmpty()) {
            ((availableDp - (visible.size - 1) * CARD_GAP_DP).toFloat() / visible.size)
                .coerceIn(MIN_CARD_DP.toFloat(), MAX_CARD_DP.toFloat())
        } else {
            -1f
        }

        val widthDp = widgetWidthDp(options)
        // Width available to a card's content (px). Used both to abbreviate long titles
        // (fitTitle) and to fit the time + room row (see bindCard).
        val titleMaxWidthPx = titleMaxWidthPx(context, widthDp)

        val views = RemoteViews(context.packageName, R.layout.widget_schedule)
        bindWidget(context, views, visible, cardCount, cardHeightDp, titleMaxWidthPx)
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
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun widgetHeightDp(options: Bundle): Int {
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return when {
            maxHeight > 0 -> maxHeight
            minHeight > 0 -> minHeight
            else -> CARD_HEIGHT_DP + 2 * CARD_INSET_DP  // default → 1 card
        }
    }

    // MIN_WIDTH is the widget's portrait width (the one shown on a normal home screen).
    private fun widgetWidthDp(options: Bundle): Int {
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val maxWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
        return when {
            minWidth > 0 -> minWidth
            maxWidth > 0 -> maxWidth
            else -> 250  // sensible default before the launcher reports a size
        }
    }

    // Pixels available to a title = widget width minus the box inset and the card's own
    // horizontal padding, both sides. This is what fitTitle measures names against.
    private fun titleMaxWidthPx(context: Context, widthDp: Int): Float {
        val contentDp = widthDp - 2 * CARD_INSET_DP - 2 * CARD_TEXT_PADDING_DP
        return contentDp * context.resources.displayMetrics.density
    }

    // A Paint configured like the title TextView (14sp, bold) so measureText matches
    // roughly what the widget will render.
    private fun titlePaint(context: Context): Paint {
        val sizePx = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_SP, TITLE_TEXT_SP, context.resources.displayMetrics
        )
        return Paint().apply {
            textSize = sizePx
            typeface = Typeface.DEFAULT_BOLD
            isAntiAlias = true
        }
    }

    // If the full name fits maxWidthPx, keep it. Otherwise abbreviate every word except
    // the last to an initial, e.g. "Bazy danych" -> "B.Danych". Single-word names can't
    // be abbreviated and are returned unchanged (the TextView still ellipsizes as a last
    // resort on an extremely narrow widget).
    private fun fitTitle(paint: Paint, name: String, maxWidthPx: Float): String {
        if (maxWidthPx <= 0f || paint.measureText(name) <= maxWidthPx) return name
        val words = name.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
        if (words.size <= 1) return name
        val lead = words.dropLast(1).joinToString("") { "${it.first().uppercaseChar()}." }
        val last = words.last().replaceFirstChar { it.uppercaseChar() }
        return "$lead$last"
    }

    // A Paint configured like the time/room row (11sp, sans-serif-medium) for measuring.
    private fun timePaint(context: Context): Paint {
        val sizePx = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_SP, TIME_TEXT_SP, context.resources.displayMetrics
        )
        return Paint().apply {
            textSize = sizePx
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            isAntiAlias = true
        }
    }

    // Short room = the last whitespace-separated token, e.g. "WChrobrego 208" -> "208".
    // Single-token rooms ("Aula") are returned unchanged.
    private fun shortRoom(location: String): String = location.trim().substringAfterLast(' ')

    // How many cards fit if each is shrunk to MIN_CARD_DP — the API 31+ path, where
    // card heights are flexible. Using the MINIMUM height here is what lets a nearly-
    // full leftover fit one extra (slightly shorter) card instead of wasting it as
    // white space. The exact per-card height is then computed in updateWidget and the
    // cards grow back up (toward MAX_CARD_DP) to fill the box. availableDp already
    // excludes the constant border (2 × inset). Clamped to [1, MAX_CARDS].
    private fun flexCapacity(availableDp: Int): Int {
        val cardUnit = MIN_CARD_DP + CARD_GAP_DP
        return ((availableDp + CARD_GAP_DP) / cardUnit).coerceIn(1, MAX_CARDS)
    }

    // Fixed-height fallback for pre-API-31 devices (no setViewLayoutHeight): how many
    // 62dp cards fit. The box keeps a CONSTANT CARD_INSET_DP border with cards pinned
    // to the top (see widget_schedule.xml); we reserve that border (2×) and pack as
    // many fixed-height cards as fit. Any leftover shows as plain white box below the
    // last card. Clamped to [1, MAX_CARDS].
    //   n = floor((height + gap - 2*inset) / (cardHeight + gap))
    private fun cardCountForHeight(heightDp: Int): Int {
        val available = heightDp + CARD_GAP_DP - 2 * CARD_INSET_DP
        val cardUnit = CARD_HEIGHT_DP + CARD_GAP_DP
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

    private fun bindWidget(context: Context, views: RemoteViews, lectures: List<LectureItem>, cardCount: Int, cardHeightDp: Float, titleMaxWidthPx: Float) {
        val density = context.resources.displayMetrics.density
        val paint = titlePaint(context)
        val timePaint = timePaint(context)
        val rectorAllowancePx = RECTOR_ICON_ALLOWANCE_DP * density
        val timeIconPx = TIME_ICON_ALLOWANCE_DP * density
        val roomLeadPx = ROOM_LEAD_ALLOWANCE_DP * density
        val slots = listOf(
            CardSlot(R.id.widget_card_1, R.id.widget_name_1, R.id.widget_time_1, R.id.widget_location_1, R.id.widget_progress_1, R.drawable.widget_card_grad_0),
            CardSlot(R.id.widget_card_2, R.id.widget_name_2, R.id.widget_time_2, R.id.widget_location_2, R.id.widget_progress_2, R.drawable.widget_card_grad_1),
            CardSlot(R.id.widget_card_3, R.id.widget_name_3, R.id.widget_time_3, R.id.widget_location_3, R.id.widget_progress_3, R.drawable.widget_card_grad_2),
            CardSlot(R.id.widget_card_4, R.id.widget_name_4, R.id.widget_time_4, R.id.widget_location_4, R.id.widget_progress_4, R.drawable.widget_card_grad_3),
            CardSlot(R.id.widget_card_5, R.id.widget_name_5, R.id.widget_time_5, R.id.widget_location_5, R.id.widget_progress_5, R.drawable.widget_card_grad_4),
            CardSlot(R.id.widget_card_6, R.id.widget_name_6, R.id.widget_time_6, R.id.widget_location_6, R.id.widget_progress_6, R.drawable.widget_card_grad_5),
            CardSlot(R.id.widget_card_7, R.id.widget_name_7, R.id.widget_time_7, R.id.widget_location_7, R.id.widget_progress_7, R.drawable.widget_card_grad_6),
            // Slots 8–10 for tall widgets. Only 8 gradients exist (grad_0..7), so the
            // colors cycle: slot 8 → grad_7, then wrap around to grad_0, grad_1.
            CardSlot(R.id.widget_card_8, R.id.widget_name_8, R.id.widget_time_8, R.id.widget_location_8, R.id.widget_progress_8, R.drawable.widget_card_grad_7),
            CardSlot(R.id.widget_card_9, R.id.widget_name_9, R.id.widget_time_9, R.id.widget_location_9, R.id.widget_progress_9, R.drawable.widget_card_grad_0),
            CardSlot(R.id.widget_card_10, R.id.widget_name_10, R.id.widget_time_10, R.id.widget_location_10, R.id.widget_progress_10, R.drawable.widget_card_grad_1),
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
                gradientRes = slot.gradientRes,
                cardHeightDp = cardHeightDp,
                paint = paint,
                titleMaxWidthPx = titleMaxWidthPx,
                rectorAllowancePx = rectorAllowancePx,
                timePaint = timePaint,
                timeIconPx = timeIconPx,
                roomLeadPx = roomLeadPx)
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
        gradientRes: Int,
        cardHeightDp: Float,
        paint: Paint,
        titleMaxWidthPx: Float,
        rectorAllowancePx: Float,
        timePaint: Paint,
        timeIconPx: Float,
        roomLeadPx: Float
    ) {
        if (idx >= lectures.size) {
            views.setViewVisibility(cardId, View.GONE)
            return
        }

        val lecture = lectures[idx]
        views.setViewVisibility(cardId, View.VISIBLE)
        // Flexible card height (API 31+). cardHeightDp <= 0 means "keep the layout's
        // fixed height" (older devices), so we leave the card untouched there.
        if (cardHeightDp > 0f && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setViewLayoutHeight(cardId, cardHeightDp, TypedValue.COMPLEX_UNIT_DIP)
        }
        // Fit the time + room on one line, shrinking to keep the room visible even on a
        // narrow widget: prefer full time + full room; else full time + short room (just
        // the room number, e.g. "WChrobrego 208" -> "208"); else start-only time + short
        // room. The room is dropped only when the lecture has none.
        val timeFull = "${lecture.start} – ${lecture.end}"
        val roomShort = shortRoom(lecture.location)
        fun rowFits(time: String, room: String): Boolean {
            var w = timeIconPx + timePaint.measureText(time)
            if (room.isNotEmpty()) w += roomLeadPx + timePaint.measureText(room)
            return w <= titleMaxWidthPx
        }
        val timeText: String
        val roomText: String
        when {
            lecture.location.isEmpty() -> { timeText = timeFull; roomText = "" }
            rowFits(timeFull, lecture.location) -> { timeText = timeFull; roomText = lecture.location }
            rowFits(timeFull, roomShort) -> { timeText = timeFull; roomText = roomShort }
            else -> { timeText = lecture.start; roomText = roomShort }
        }

        // Strike through the time and room too (alongside the title) for rector
        // hours / canceled lectures, matching the in-app card.
        views.setTextViewText(timeId, if (lecture.isRector) strikeThrough(timeText) else timeText)
        if (roomText.isNotEmpty()) {
            views.setTextViewText(
                locationId,
                if (lecture.isRector) strikeThrough(roomText) else roomText
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
            // The leading warning icon eats some title width, so budget for it.
            val rectorTitle = fitTitle(paint, lecture.name, titleMaxWidthPx - rectorAllowancePx)
            views.setTextViewText(nameId, strikeThrough(rectorTitle))
            views.setTextViewCompoundDrawablesRelative(nameId, R.drawable.ic_widget_warning, 0, 0, 0)
            // No live progress bar for rector / canceled lectures (matches the app).
            views.setViewVisibility(progressId, View.GONE)
            return
        }

        views.setInt(cardId, "setBackgroundResource", gradientRes)
        views.setTextViewText(nameId, fitTitle(paint, lecture.name, titleMaxWidthPx))
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
