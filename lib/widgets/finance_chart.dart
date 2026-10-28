import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class FinanceChart extends StatelessWidget {
  final Map<String, double> categoryExpenses;
  final Map<String, Category> categoryMap;

  const FinanceChart({
    super.key,
    required this.categoryExpenses,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalExpense = categoryExpenses.values.fold(0.0, (sum, v) => sum + v);

    if (totalExpense == 0.0) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'Nenhuma despesa registrada no período.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      );
    }

    final sortedEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(4).toList();
    final remainingSum = sortedEntries.skip(4).fold(0.0, (sum, e) => sum + e.value);

    final sections = <PieChartSectionData>[];

    for (final entry in topEntries) {
      final cat = categoryMap[entry.key];
      final color = cat != null ? Color(cat.colorValue) : AppColors.indigo;
      final pct = (entry.value / totalExpense) * 100;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 28,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (remainingSum > 0) {
      final pct = (remainingSum / totalExpense) * 100;
      sections.add(
        PieChartSectionData(
          color: const Color(0xFF94A3B8),
          value: remainingSum,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 28,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 140,
          width: 140,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 36,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: topEntries.map((entry) {
              final cat = categoryMap[entry.key];
              final catName = cat?.name ?? 'Outros';
              final color = cat != null ? Color(cat.colorValue) : AppColors.indigo;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
