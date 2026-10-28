import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class FinancialHealthInsightCard extends StatelessWidget {
  final AppState appState;

  const FinancialHealthInsightCard({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final month = appState.selectedMonth;
    final savingsRate = appState.getSavingsRate(month);
    final alerts = appState.getBudgetAlerts(month);

    String badgeLabel;
    Color badgeColor;
    String insightText;
    IconData badgeIcon;

    if (savingsRate >= 30.0) {
      badgeLabel = 'Excelente';
      badgeColor = AppColors.emeraldDark;
      badgeIcon = Icons.stars_rounded;
      insightText = 'Você poupou ${savingsRate.toStringAsFixed(1)}% da sua renda este mês! Excelente capacidade de investimento.';
    } else if (savingsRate >= 15.0) {
      badgeLabel = 'Muito Bom';
      badgeColor = AppColors.emerald;
      badgeIcon = Icons.check_circle_rounded;
      insightText = 'Você guardou ${savingsRate.toStringAsFixed(1)}% dos seus ganhos, alinhado às melhores práticas financeiras.';
    } else if (savingsRate > 0) {
      badgeLabel = 'Atenção';
      badgeColor = AppColors.amber;
      badgeIcon = Icons.warning_amber_rounded;
      insightText = 'Economia de ${savingsRate.toStringAsFixed(1)}%. Margem estreita para imprevistos.';
    } else {
      badgeLabel = 'Déficit';
      badgeColor = AppColors.rose;
      badgeIcon = Icons.error_outline_rounded;
      insightText = 'Despesas superaram as receitas no mês. Revise seus gastos essenciais.';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(badgeIcon, color: badgeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Saúde Financeira',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insightText,
            style: TextStyle(fontSize: 13, color: textSecondary, height: 1.35),
          ),

          // Alertas Orçamentários (se houver)
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            const SizedBox(height: 12),
            Text(
              'Atenção ao Orçamento (${alerts.length})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amber),
            ),
            const SizedBox(height: 8),
            ...alerts.map((al) {
              final Category cat = al['category'] as Category;
              final double spent = al['spent'] as double;
              final double limit = al['limit'] as double;
              final double pct = al['percent'] as double;
              final bool isExceeded = al['isExceeded'] as bool;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      isExceeded ? Icons.arrow_upward_rounded : Icons.info_outline,
                      size: 14,
                      color: isExceeded ? AppColors.rose : AppColors.amber,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${cat.name}: ${CurrencyFormatter.format(spent)} de ${CurrencyFormatter.format(limit)} (${pct.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExceeded ? AppColors.rose : textPrimary,
                          fontWeight: isExceeded ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
