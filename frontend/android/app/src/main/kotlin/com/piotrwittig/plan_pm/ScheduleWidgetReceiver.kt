package com.piotrwittig.plan_pm

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import com.piotrwittig.plan_pm.ScheduleWidget
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import es.antonborri.home_widget.HomeWidgetPlugin

class ScheduleWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ScheduleWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "es.antonborri.home_widget.action.BACKGROUND") {
            val glanceId = HomeWidgetPlugin.getData(context).getString("glanceId", "")
        }
    }
}
