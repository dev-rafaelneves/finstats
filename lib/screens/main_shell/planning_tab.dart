import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/ios_grouped_section.dart';
import '../../widgets/ios_list_tile.dart';
import '../analytics_screen.dart';
import '../credit_cards_screen.dart';
import '../monthly_comparator_screen.dart';
import '../recurring_transactions_screen.dart';

class PlanningTab extends StatelessWidget {
  final AppState appState;

  const PlanningTab({super.key, required this.appState});

  void _showSetBudgetDialog(BuildContext context, Category category, Budget? currentBudget) {
    final controller = TextEditingController(
      text: currentBudget != null ? currentBudget.limitAmount.toStringAsFixed(2) : '',
    );

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Meta para ${category.name}'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              const Text('Defina o teto mensal de gastos para esta categoria:'),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('R\$ ', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                placeholder: '0,00',
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final amount = double.tryParse(controller.text.replaceAll(',', '.').trim());
              if (amount != null && amount > 0) {
                Navigator.of(ctx).pop();
                HapticFeedback.lightImpact();
                final monthKey = CurrencyFormatter.formatMonthYearKey(appState.selectedMonth);
                await appState.setBudget(
                  categoryId: category.id,
                  limitAmount: amount,
                  monthYear: monthKey,
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final selectedMonth = appState.selectedMonth;
    final categoryExpenses = appState.getCategoryExpenses(selectedMonth);
    final expenseCategories = appState.categories.where((c) => c.type == TransactionType.expense).toList();
    final budgetMap = {for (var b in appState.budgets) b.categoryId: b};
    final creditCards = appState.creditCards;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: isDark
                ? AppColors.darkBackground.withValues(alpha: 0.9)
                : AppColors.lightBackground.withValues(alpha: 0.9),
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              centerTitle: false,
              title: Text(
                'Metas & Análise',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  color: textPrimary,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Seção Apple Grouped: MÓDULOS DE GESTÃO
                      IosGroupedSection(
                        header: 'Módulos de Gestão',
                        children: [
                          IosListTile(
                            icon: Icons.credit_card_rounded,
                            iconBackgroundColor: AppColors.purple.withValues(alpha: 0.15),
                            iconColor: AppColors.purple,
                            title: 'Cartões de Crédito',
                            subtitle: '${creditCards.length} cartão(ões) cadastrado(s)',
                            showChevron: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CreditCardsScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                          IosListTile(
                            icon: Icons.event_repeat_rounded,
                            iconBackgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                            iconColor: AppColors.emeraldDark,
                            title: 'Contas Fixas & Assinaturas',
                            subtitle: '${appState.recurringRules.length} regra(s) ativa(s)',
                            showChevron: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecurringTransactionsScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                          IosListTile(
                            icon: Icons.compare_arrows_rounded,
                            iconBackgroundColor: AppColors.indigo.withValues(alpha: 0.15),
                            iconColor: AppColors.indigo,
                            title: 'Comparador Mês a Mês',
                            subtitle: 'Análise comparativa direta entre dois meses',
                            showChevron: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MonthlyComparatorScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                          IosListTile(
                            icon: Icons.insights_rounded,
                            iconBackgroundColor: AppColors.sky.withValues(alpha: 0.15),
                            iconColor: AppColors.sky,
                            title: 'Inteligência Financeira',
                            subtitle: 'Evolução do fluxo de caixa e patrimônio líquido',
                            showChevron: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AnalyticsScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // Seção Apple Grouped: ORÇAMENTO POR CATEGORIA
                      IosGroupedSection(
                        header: 'Teto de Gastos • ${CurrencyFormatter.formatMonthYear(selectedMonth)}',
                        footer: 'Toque em uma categoria para ajustar ou definir o teto mensal.',
                        children: expenseCategories.map((cat) {
                          final spent = categoryExpenses[cat.id] ?? 0.0;
                          final budget = budgetMap[cat.id];
                          final hasBudget = budget != null && budget.limitAmount > 0;
                          final limit = hasBudget ? budget.limitAmount : 0.0;
                          final progress = hasBudget ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                          final isOver = hasBudget && spent > limit;

                          return InkWell(
                            onTap: () => _showSetBudgetDialog(context, cat, budget),
                            child: Padding(
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
                                          color: Color(cat.colorValue).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          CategoryIconHelper.getIcon(cat.iconName),
                                          size: 18,
                                          color: Color(cat.colorValue),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Text(
                                              hasBudget
                                                  ? 'Gasto: ${CurrencyFormatter.format(spent)} de ${CurrencyFormatter.format(limit)}'
                                                  : 'Gasto: ${CurrencyFormatter.format(spent)} (sem teto)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isOver ? AppColors.rose : textSecondary,
                                                fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                  if (hasBudget) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 5,
                                        backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                        valueColor: AlwaysStoppedAnimation(
                                          isOver
                                              ? AppColors.rose
                                              : (progress > 0.8 ? AppColors.amber : AppColors.emeraldDark),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
