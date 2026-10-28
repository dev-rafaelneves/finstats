import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/ios_grouped_section.dart';

class MonthlyComparatorScreen extends StatefulWidget {
  final AppState appState;

  const MonthlyComparatorScreen({super.key, required this.appState});

  @override
  State<MonthlyComparatorScreen> createState() => _MonthlyComparatorScreenState();
}

class _MonthlyComparatorScreenState extends State<MonthlyComparatorScreen> {
  late DateTime _baseMonth;
  late DateTime _compareMonth;

  @override
  void initState() {
    super.initState();
    final now = widget.appState.selectedMonth;
    _compareMonth = DateTime(now.year, now.month, 1);
    _baseMonth = DateTime(now.year, now.month - 1, 1);
  }

  void _swapMonths() {
    HapticFeedback.selectionClick();
    setState(() {
      final tmp = _baseMonth;
      _baseMonth = _compareMonth;
      _compareMonth = tmp;
    });
  }

  void _selectMonth({required bool isBase}) {
    final current = isBase ? _baseMonth : _compareMonth;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        DateTime tempDate = current;
        return Container(
          height: 280,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 0.8,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.rose)),
                    ),
                    Text(
                      isBase ? 'Mês Base (A)' : 'Mês Comparado (B)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          if (isBase) {
                            _baseMonth = tempDate;
                          } else {
                            _compareMonth = tempDate;
                          }
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(color: AppColors.emeraldDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: current,
                  minimumDate: DateTime(2020, 1),
                  maximumDate: DateTime(2035, 12),
                  onDateTimeChanged: (date) {
                    tempDate = DateTime(date.year, date.month, 1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final comparison = widget.appState.compareMonths(_baseMonth, _compareMonth);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Comparador Mensal'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              // Selector Card (A vs B)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    // Base Month Pill
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectMonth(isBase: true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mês Base (A)',
                                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatMonthYear(_baseMonth),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Swap Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.indigo),
                        onPressed: _swapMonths,
                        tooltip: 'Inverter seleção',
                      ),
                    ),

                    // Compare Month Pill
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectMonth(isBase: false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldDark.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Comparado (B)',
                                style: TextStyle(fontSize: 10, color: AppColors.emeraldDark, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatMonthYear(_compareMonth),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KPI Delta Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      title: 'Despesas (B)',
                      baseVal: comparison.base.totalExpense,
                      compareVal: comparison.compare.totalExpense,
                      diffVal: comparison.expenseDiff,
                      diffPct: comparison.expenseDiffPercent,
                      isExpense: true,
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricPill(
                      title: 'Receitas (B)',
                      baseVal: comparison.base.totalIncome,
                      compareVal: comparison.compare.totalIncome,
                      diffVal: comparison.incomeDiff,
                      diffPct: comparison.incomeDiffPercent,
                      isExpense: false,
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      title: 'Economia Líquida (B)',
                      baseVal: comparison.base.netSavings,
                      compareVal: comparison.compare.netSavings,
                      diffVal: comparison.savingsDiff,
                      diffPct: 0.0,
                      isExpense: false,
                      isSavings: true,
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRatePill(
                      title: 'Taxa Poupança (B)',
                      baseRate: comparison.base.savingsRate,
                      compareRate: comparison.compare.savingsRate,
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Breakdown Categoria a Categoria em Inset Grouped Section
              IosGroupedSection(
                header: 'Variação por Categoria (B vs A)',
                footer: 'Verde indica redução de custos ou aumento de receitas; vermelho indica aumento de despesas.',
                children: comparison.categoryComparisons.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text('Nenhuma categoria para comparar.', style: TextStyle(color: textSecondary)),
                          ),
                        ),
                      ]
                    : comparison.categoryComparisons.map((catComp) {
                        final isIncrease = catComp.diffAmount > 0;
                        final isZero = catComp.diffAmount == 0;
                        final pillColor = isIncrease ? AppColors.rose : (isZero ? Colors.grey : AppColors.emeraldDark);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Color(catComp.category.colorValue).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      CategoryIconHelper.getIcon(catComp.category.iconName),
                                      size: 16,
                                      color: Color(catComp.category.colorValue),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      catComp.category.name,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: pillColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isIncrease ? Icons.arrow_upward_rounded : (isZero ? Icons.remove : Icons.arrow_downward_rounded),
                                          size: 12,
                                          color: pillColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${isIncrease ? "+" : ""}${CurrencyFormatter.format(catComp.diffAmount)} (${catComp.diffPercent.toStringAsFixed(0)}%)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: pillColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Base (A): ${CurrencyFormatter.format(catComp.baseAmount)}',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                  Text(
                                    'Comparado (B): ${CurrencyFormatter.format(catComp.compareAmount)}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required String title,
    required double baseVal,
    required double compareVal,
    required double diffVal,
    required double diffPct,
    required bool isExpense,
    bool isSavings = false,
    required bool isDark,
    required Color textPrimary,
  }) {
    final isIncrease = diffVal > 0;
    final isZero = diffVal == 0;

    Color badgeColor;
    if (isExpense) {
      badgeColor = isIncrease ? AppColors.rose : (isZero ? Colors.grey : AppColors.emeraldDark);
    } else {
      badgeColor = isIncrease ? AppColors.emeraldDark : (isZero ? Colors.grey : AppColors.rose);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(compareVal),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward_rounded : (isZero ? Icons.remove : Icons.arrow_downward_rounded),
                size: 12,
                color: badgeColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${isIncrease ? "+" : ""}${CurrencyFormatter.format(diffVal)}${isSavings ? "" : " (${diffPct.toStringAsFixed(0)}%)"}',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatePill({
    required String title,
    required double baseRate,
    required double compareRate,
    required bool isDark,
    required Color textPrimary,
  }) {
    final diff = compareRate - baseRate;
    final isUp = diff > 0;
    final isZero = diff == 0;
    final badgeColor = isUp ? AppColors.emeraldDark : (isZero ? Colors.grey : AppColors.rose);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            '${compareRate.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_upward_rounded : (isZero ? Icons.remove : Icons.arrow_downward_rounded),
                size: 12,
                color: badgeColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${isUp ? "+" : ""}${diff.toStringAsFixed(1)} p.p.',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
