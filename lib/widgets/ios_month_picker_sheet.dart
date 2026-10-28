import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class IosMonthPickerSheet extends StatefulWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const IosMonthPickerSheet({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTime selectedMonth,
    required ValueChanged<DateTime> onMonthSelected,
  }) {
    HapticFeedback.lightImpact();
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => IosMonthPickerSheet(
        selectedMonth: selectedMonth,
        onMonthSelected: onMonthSelected,
      ),
    );
  }

  @override
  State<IosMonthPickerSheet> createState() => _IosMonthPickerSheetState();
}

class _IosMonthPickerSheetState extends State<IosMonthPickerSheet> {
  late int _selectedYear;

  static const List<String> _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const List<String> _monthShortNames = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedMonth.year;
  }

  void _selectMonth(int month) {
    HapticFeedback.selectionClick();
    final newDate = DateTime(_selectedYear, month, 1);
    widget.onMonthSelected(newDate);
    Navigator.of(context).pop();
  }

  void _selectCurrentMonth() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final newDate = DateTime(now.year, now.month, 1);
    widget.onMonthSelected(newDate);
    Navigator.of(context).pop();
  }

  void _changeYear(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedYear += delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Indicator Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Fechar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Selecionar Mês',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                      color: textPrimary,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: _selectCurrentMonth,
                    child: const Text(
                      'Mês Atual',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 0.8, color: borderColor),

            // Seletor de Ano no estilo iOS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _changeYear(-1),
                    icon: Icon(Icons.chevron_left_rounded, color: textPrimary, size: 28),
                    splashRadius: 24,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Text(
                      '$_selectedYear',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _changeYear(1),
                    icon: Icon(Icons.chevron_right_rounded, color: textPrimary, size: 28),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),

            // Grid 3x4 com os 12 Meses (Padrão Apple HIG)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (context, index) {
                      final monthNumber = index + 1;
                      final isSelected = _selectedYear == widget.selectedMonth.year &&
                          monthNumber == widget.selectedMonth.month;
                      final isTodayMonth = _selectedYear == now.year && monthNumber == now.month;

                      return GestureDetector(
                        onTap: () => _selectMonth(monthNumber),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [AppColors.emerald, AppColors.emeraldDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emeraldDark
                                  : (isTodayMonth ? AppColors.emeraldDark.withValues(alpha: 0.4) : borderColor),
                              width: isSelected || isTodayMonth ? 1.5 : 0.8,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.emeraldDark.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _monthShortNames[index].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: isSelected ? Colors.white : textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _monthNames[index],
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.85)
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (isTodayMonth && !isSelected)
                                Positioned(
                                  top: 5,
                                  right: 7,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.emeraldDark,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
