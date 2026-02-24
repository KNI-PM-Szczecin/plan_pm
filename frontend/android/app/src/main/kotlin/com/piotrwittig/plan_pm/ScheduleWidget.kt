package com.piotrwittig.plan_pm

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.Button
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.util.Date

// Custom Colors for Glassmorphism
private val GlassBackground = ColorProvider(
    day = Color(0x33FFFFFF), // 20% white for subtle translucency
    night = Color(0x33000000) // 20% black for dark mode
)

private val GlassSurface = ColorProvider(
    day = Color(0xCCFFFFFF), // 80% white - readable but slightly transparent
    night = Color(0xB31C1C1E) // 70% dark grey - readability in dark mode
)

class ScheduleWidget : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                WidgetContent(context)
            }
        }
    }

@Composable
    private fun WidgetContent(context: Context) {
        val prefs = HomeWidgetPlugin.getData(context)
        
        val glancePrefs = currentState<androidx.datastore.preferences.core.Preferences>()
        val selectedDayOffset = glancePrefs[androidx.datastore.preferences.core.intPreferencesKey("selected_day_offset")] ?: 0
        
        val scheduleJsonStr = prefs.getString("schedule_data_$selectedDayOffset", "[]") ?: "[]"
        val dayName = prefs.getString("day_name_$selectedDayOffset", "Dzisiaj") ?: "Dzisiaj"
        val eventColorStyle = prefs.getString("event_color_style", "current") ?: "current"
        val primaryColorHex = prefs.getString("primary_color", "#FF409CFF") ?: "#FF409CFF"
        
        val lectures = try {
            parseLectures(scheduleJsonStr)
        } catch (e: Exception) {
            emptyList()
        }

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlassBackground)
                .cornerRadius(24.dp)
                .padding(16.dp)
        ) {
            // Header
            Row(
                modifier = GlanceModifier.fillMaxWidth().padding(bottom = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Left Button
                Box(
                    modifier = GlanceModifier
                        .padding(8.dp)
                        .clickable(actionRunCallback<ChangeDayAction>(
                            actionParametersOf(DayOffsetKey to (selectedDayOffset - 1))
                        )),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "<",
                        style = TextStyle(
                            color = GlanceTheme.colors.onBackground,
                            fontWeight = FontWeight.Medium,
                            fontSize = 24.sp
                        )
                    )
                }

                Text(
                    text = dayName,
                    modifier = GlanceModifier.defaultWeight().padding(horizontal = 8.dp),
                    style = TextStyle(
                        color = GlanceTheme.colors.onBackground,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    )
                )

                // Right Button
                Box(
                    modifier = GlanceModifier
                        .padding(8.dp)
                        .clickable(actionRunCallback<ChangeDayAction>(
                            actionParametersOf(DayOffsetKey to (selectedDayOffset + 1))
                        )),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = ">",
                        style = TextStyle(
                            color = GlanceTheme.colors.onBackground,
                            fontWeight = FontWeight.Medium,
                            fontSize = 24.sp
                        )
                    )
                }
            }

            // List
            if (lectures.isEmpty()) {
                Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        text = "Brak zajęć",
                        style = TextStyle(
                            color = GlanceTheme.colors.onBackground,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
            } else {
                LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                    items(lectures) { lecture ->
                        LectureItem(context, lecture, eventColorStyle, primaryColorHex)
                    }
                }
            }
        }
    }
}

// TodayWidget
class TodayWidget : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                WidgetContent(context)
            }
        }
    }

    @Composable
    private fun WidgetContent(context: Context) {
        val prefs = HomeWidgetPlugin.getData(context)
        val scheduleJsonStr = prefs.getString("schedule_data_0", "[]") ?: "[]"
        val eventColorStyle = prefs.getString("event_color_style", "current") ?: "current"
        val primaryColorHex = prefs.getString("primary_color", "#FF409CFF") ?: "#FF409CFF"
        
        val lectures = try {
            parseLectures(scheduleJsonStr)
        } catch (e: Exception) {
            emptyList()
        }

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlassBackground)
                .cornerRadius(24.dp)
                .padding(16.dp)
        ) {
            // Header
            Row(
                modifier = GlanceModifier.fillMaxWidth().padding(bottom = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Dzisiaj",
                    style = TextStyle(
                        color = GlanceTheme.colors.onBackground,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    )
                )
            }

            // List
            if (lectures.isEmpty()) {
                Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        text = "Brak zajęć na dzisiaj",
                        style = TextStyle(
                            color = GlanceTheme.colors.onBackground,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
            } else {
                LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                    items(lectures) { lecture ->
                        LectureItem(context, lecture, eventColorStyle, primaryColorHex)
                    }
                }
            }
        }
    }
}

@Composable
private fun LectureItem(context: Context, lecture: LectureData, eventColorStyle: String, primaryColorHex: String) {
    val launchIntent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }

    val styleType = when (eventColorStyle) {
        "pastel" -> "pastel"
        "vibrant" -> "vibrant"
        "monochrome" -> "monochrome"
        else -> "default"
    }

    val textColor = if (styleType == "pastel") ColorProvider(day = Color(0xDE000000), night = Color(0xDE000000)) else ColorProvider(day = Color.White, night = Color.White)
    val secondaryTextColor = if (styleType == "pastel") ColorProvider(day = Color(0x99000000), night = Color(0x99000000)) else ColorProvider(day = Color(0xCCFFFFFF), night = Color(0xCCFFFFFF))

    val backgroundModifier = if (styleType == "monochrome") {
        try {
            val colorInt = android.graphics.Color.parseColor(primaryColorHex)
            val baseColor = Color(colorInt)
            // Make it slightly transparent for glassy look
            val glassyColor = baseColor.copy(alpha = 0.8f) 
            GlanceModifier.background(ColorProvider(day = glassyColor, night = glassyColor)).cornerRadius(12.dp)
        } catch (e: Exception) {
            GlanceModifier.background(GlanceTheme.colors.primary).cornerRadius(12.dp)
        }
    } else {
        val drawableName = "tile_${styleType}_${lecture.idx % 8}"
        val resId = context.resources.getIdentifier(drawableName, "drawable", context.packageName)
        if (resId != 0) {
            GlanceModifier.background(androidx.glance.ImageProvider(resId))
        } else {
            GlanceModifier.background(GlanceTheme.colors.surface).cornerRadius(12.dp)
        }
    }

    // Margin wrapper
    Column(modifier = GlanceModifier.fillMaxWidth().padding(bottom = 8.dp)) {
        Column(
            modifier = GlanceModifier
                .fillMaxWidth()
                .then(backgroundModifier)
                .padding(16.dp)
                .clickable(actionStartActivity(launchIntent))
        ) {
            Text(
                text = lecture.name,
                style = TextStyle(
                    color = textColor,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp
                )
            )
            Spacer(modifier = GlanceModifier.height(6.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "${lecture.startTime} - ${lecture.endTime}",
                    style = TextStyle(
                        color = secondaryTextColor,
                        fontSize = 13.sp
                    )
                )
                Spacer(modifier = GlanceModifier.size(12.dp))
                Text(
                    text = lecture.room ?: "---",
                    style = TextStyle(
                        color = secondaryTextColor,
                        fontSize = 13.sp
                    )
                )
            }
        }
    }
}

private fun parseLectures(jsonStr: String): List<LectureData> {
    val list = mutableListOf<LectureData>()
    val jsonArray = JSONArray(jsonStr)
    for (i in 0 until jsonArray.length()) {
        val obj = jsonArray.getJSONObject(i)
        list.add(
            LectureData(
                idx = if (obj.has("idx")) obj.getInt("idx") else i,
                name = obj.getString("name"),
                startTime = obj.getString("startTime"),
                endTime = obj.getString("endTime"),
                room = if (obj.has("room") && !obj.isNull("room")) obj.getString("room") else null,
                building = if (obj.has("building") && !obj.isNull("building")) obj.getString("building") else null
            )
        )
    }
    return list
}

data class LectureData(
    val idx: Int,
    val name: String,
    val startTime: String,
    val endTime: String,
    val room: String?,
    val building: String?
)

val DayOffsetKey = ActionParameters.Key<Int>("day_offset")

class ChangeDayAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val newOffset = parameters[DayOffsetKey] ?: 0
        // Limit offset reasonable, like -30 to 30 days
        val safeOffset = newOffset.coerceIn(-30, 30)
        
        androidx.glance.appwidget.state.updateAppWidgetState(context, glanceId) { mutablePrefs ->
            mutablePrefs[androidx.datastore.preferences.core.intPreferencesKey("selected_day_offset")] = safeOffset
        }
        
        ScheduleWidget().update(context, glanceId)
    }
}
