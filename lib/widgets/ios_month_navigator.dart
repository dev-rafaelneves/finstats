import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'ios_month_picker_sheet.dart';

class IosMonthNavigator extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const IosMonthNavigator({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  void _previousMonth() {
    HapticFeedback.selectionClick();
    final prev = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    onMonthChanged(prev);
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    final next = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    onMonthChanged(next);
  }

  void _openSheet(BuildContext context) {
    IosMonthPickerSheet.show(
      context: context,
      selectedMonth: selectedMonth,
      onMonthSelected: onMonthChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Botão Mês Anterior (Seta Esquerda)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _previousMonth,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Botão Central de Seleção do Mês (Abre Sheet no Padrão Apple)
              Expanded(
                child: GestureDetector(
                  onTap: () => _openSheet(context),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentMonth
                            ? borderColor
                            : AppColors.emeraldDark.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 15,
                          color: isCurrentMonth ? AppColors.emeraldDark : AppColors.indigo,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.formatMonthYear(selectedMonth),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Botão Próximo Mês (Seta Direita)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _nextMonth,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
