import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class CashFlowEvolutionChart extends StatefulWidget {
  final List<MonthlySummary> history;

  const CashFlowEvolutionChart({super.key, required this.history});

  @override
  State<CashFlowEvolutionChart> createState() => _CashFlowEvolutionChartState();
}

class _CashFlowEvolutionChartState extends State<CashFlowEvolutionChart> {
  bool _isLineChart = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.history.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sem histórico suficiente para exibir o gráfico.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chart Mode Switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildLegendItem('Receitas', AppColors.emeraldDark),
                const SizedBox(width: 14),
                _buildLegendItem('Despesas', AppColors.rose),
              ],
            ),
            IconButton(
              icon: Icon(
                _isLineChart ? Icons.bar_chart_rounded : Icons.show_chart_rounded,
                size: 20,
                color: AppColors.indigo,
              ),
              tooltip: _isLineChart ? 'Ver em barras' : 'Ver em linha de tendência',
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isLineChart = !_isLineChart);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 220,
          child: _isLineChart ? _buildLineChart(isDark) : _buildBarChart(isDark),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBarChart(bool isDark) {
    double maxY = 0.0;
    for (final item in widget.history) {
      if (item.totalIncome > maxY) maxY = item.totalIncome;
      if (item.totalExpense > maxY) maxY = item.totalExpense;
    }
    if (maxY == 0.0) maxY = 1000.0;
    maxY *= 1.2;

    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < widget.history.length; i++) {
      final summary = widget.history[i];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: summary.totalIncome,
              color: AppColors.emeraldDark,
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: summary.totalExpense,
              color: AppColors.rose,
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isIncome = rodIndex == 0;
              final summary = widget.history[group.x];
              final monthName = CurrencyFormatter.formatDateShort(summary.month);
              final val = isIncome ? summary.totalIncome : summary.totalExpense;

              return BarTooltipItem(
                '$monthName\n${isIncome ? "Receita" : "Despesa"}: ${CurrencyFormatter.format(val)}',
                const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (val, meta) {
                if (val == 0 || val == meta.max) return const SizedBox.shrink();
                return Text(
                  CurrencyFormatter.formatCompact(val),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final index = val.toInt();
                if (index < 0 || index >= widget.history.length) return const SizedBox.shrink();
                final summary = widget.history[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    CurrencyFormatter.formatDateShort(summary.month),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 0.8,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildLineChart(bool isDark) {
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    double maxY = 0.0;

    for (int i = 0; i < widget.history.length; i++) {
      final summary = widget.history[i];
      incomeSpots.add(FlSpot(i.toDouble(), summary.totalIncome));
      expenseSpots.add(FlSpot(i.toDouble(), summary.totalExpense));

      if (summary.totalIncome > maxY) maxY = summary.totalIncome;
      if (summary.totalExpense > maxY) maxY = summary.totalExpense;
    }
    if (maxY == 0) maxY = 1000;
    maxY *= 1.2;

    return LineChart(
      LineChartData(
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final isIncome = spot.barIndex == 0;
                final summary = widget.history[spot.x.toInt()];
                final monthName = CurrencyFormatter.formatDateShort(summary.month);
                return LineTooltipItem(
                  '$monthName ${isIncome ? "Receita" : "Despesa"}: ${CurrencyFormatter.format(spot.y)}',
                  TextStyle(
                    color: isIncome ? AppColors.emerald : AppColors.rose,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 0.8,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (val, meta) {
                if (val == 0 || val == meta.max) return const SizedBox.shrink();
                return Text(
                  CurrencyFormatter.formatCompact(val),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final index = val.toInt();
                if (index < 0 || index >= widget.history.length) return const SizedBox.shrink();
                final summary = widget.history[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    CurrencyFormatter.formatDateShort(summary.month),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: AppColors.emeraldDark,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: AppColors.rose,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
