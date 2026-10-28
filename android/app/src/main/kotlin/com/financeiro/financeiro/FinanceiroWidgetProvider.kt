package com.financeiro.financeiro

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class FinanceiroWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.financeiro_widget).apply {
                val balance = widgetData.getString("total_balance", "R$ 0,00") ?: "R$ 0,00"
                val expense = widgetData.getString("monthly_expense", "R$ 0,00") ?: "R$ 0,00"
                val updateTime = widgetData.getString("last_update", "Atualizado") ?: "Atualizado"

                setTextViewText(R.id.widget_total_balance, balance)
                setTextViewText(R.id.widget_monthly_expense, expense)
                setTextViewText(R.id.widget_last_update, updateTime)

                // Ao clicar no widget, abre o app diretamente
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
