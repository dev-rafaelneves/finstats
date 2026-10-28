import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/finance_chart.dart';
import '../../widgets/financial_health_insight_card.dart';
import '../../widgets/ios_grouped_section.dart';
import '../../widgets/ios_list_tile.dart';
import '../../widgets/summary_card.dart';
import '../credit_cards_screen.dart';
import '../monthly_comparator_screen.dart';
import '../transaction_detail_screen.dart';

class DashboardTab extends StatelessWidget {
  final AppState appState;
  final VoidCallback onOpenNewTransaction;

  const DashboardTab({
    super.key,
    required this.appState,
    required this.onOpenNewTransaction,
  });

  void _showMonthPicker(BuildContext context) {
    final selectedMonth = appState.selectedMonth;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        DateTime tempDate = selectedMonth;
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
                    const Text(
                      'Selecionar Mês',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        appState.setSelectedMonth(tempDate);
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
                  initialDateTime: selectedMonth,
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

    final selectedMonth = appState.selectedMonth;
    final monthIncome = appState.getMonthIncome(selectedMonth);
    final monthExpense = appState.getMonthExpense(selectedMonth);
    final netSavings = appState.getMonthSavings(selectedMonth);
    final categoryExpenses = appState.getCategoryExpenses(selectedMonth);
    final monthTransactions = appState.getMonthTransactions(selectedMonth);

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
                'Visão Geral',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  color: textPrimary,
                ),
              ),
            ),
            actions: [
              // Seletor de Mês iOS
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () => _showMonthPicker(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.formatMonthYear(selectedMonth),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                    ],
                  ),
                ),
              ),

              // Botão Comparador
              IconButton(
                tooltip: 'Comparador Mês a Mês',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MonthlyComparatorScreen(appState: appState),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 20, color: AppColors.indigo),
              ),

              // Botão Novo Lançamento (+)
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: IconButton(
                  tooltip: 'Novo Lançamento',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onOpenNewTransaction();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.emeraldDark,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card Apple Health/Wallet Style - Saldo Consolidado
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SALDO CONSOLIDADO',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          netSavings >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                          size: 13,
                                          color: AppColors.emerald,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${netSavings >= 0 ? "+" : ""}${CurrencyFormatter.format(netSavings)}',
                                          style: const TextStyle(
                                            color: AppColors.emerald,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                CurrencyFormatter.format(appState.totalBalance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Resumo Mensal Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SummaryCard(
                                title: 'Receitas',
                                amount: monthIncome,
                                icon: Icons.arrow_downward_rounded,
                                accentColor: AppColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SummaryCard(
                                title: 'Despesas',
                                amount: monthExpense,
                                icon: Icons.arrow_upward_rounded,
                                accentColor: AppColors.rose,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Card de Insight de Saúde Financeira
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: FinancialHealthInsightCard(appState: appState),
                      ),

                      // Seção Apple Grouped: MINHAS CONTAS & CARTÕES
                      IosGroupedSection(
                        header: 'Minhas Contas (${appState.accounts.length})',
                        footer: 'Toque para gerenciar faturas de cartão de crédito e contas bancárias.',
                        children: [
                          ...appState.accounts.map((acc) {
                            final isCredit = acc.type == AccountType.creditCard;
                            return IosListTile(
                              icon: isCredit ? Icons.credit_card_rounded : Icons.account_balance_wallet_rounded,
                              iconBackgroundColor: Color(acc.colorValue).withValues(alpha: 0.15),
                              iconColor: Color(acc.colorValue),
                              title: acc.name,
                              subtitle: isCredit
                                  ? 'Limite disp.: ${CurrencyFormatter.format(acc.availableLimit)}'
                                  : acc.type.label,
                              showChevron: true,
                              trailing: Text(
                                CurrencyFormatter.format(acc.currentBalance),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isCredit ? AppColors.rose : textPrimary,
                                ),
                              ),
                              onTap: () {
                                if (isCredit) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CreditCardsScreen(appState: appState),
                                    ),
                                  );
                                }
                              },
                            );
                          }),
                        ],
                      ),

                      // Seção Apple Grouped: DISTRIBUIÇÃO DE GASTOS
                      if (categoryExpenses.isNotEmpty)
                        IosGroupedSection(
                          header: 'Distribuição de Gastos',
                          contentPadding: const EdgeInsets.all(16),
                          child: FinanceChart(
                            categoryExpenses: categoryExpenses,
                            categoryMap: appState.categoryMap,
                          ),
                        ),

                      // Seção Apple Grouped: ÚLTIMAS MOVIMENTAÇÕES
                      IosGroupedSection(
                        header: 'Últimas Movimentações',
                        footer: monthTransactions.isNotEmpty
                            ? 'Exibindo os lançamentos mais recentes deste mês.'
                            : null,
                        children: monthTransactions.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                  child: Column(
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 36, color: textSecondary),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nenhuma movimentação neste mês.',
                                        style: TextStyle(color: textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            : monthTransactions.take(5).map((t) {
                                final cat = appState.categoryMap[t.categoryId];
                                final isIncome = t.type == TransactionType.income;
                                return IosListTile(
                                  icon: cat != null
                                      ? CategoryIconHelper.getIcon(cat.iconName)
                                      : Icons.category_rounded,
                                  iconBackgroundColor: cat != null
                                      ? Color(cat.colorValue).withValues(alpha: 0.15)
                                      : AppColors.emerald.withValues(alpha: 0.15),
                                  iconColor: cat != null ? Color(cat.colorValue) : AppColors.emerald,
                                  title: t.description,
                                  subtitle: '${CurrencyFormatter.formatDateShort(t.date)}${t.isInstallment ? " • ${t.installmentIndex}/${t.totalInstallments}x" : ""}',
                                  showChevron: true,
                                  trailing: Text(
                                    '${isIncome ? "+" : "-"} ${CurrencyFormatter.format(t.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isIncome ? AppColors.emeraldDark : AppColors.rose,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TransactionDetailScreen(
                                          appState: appState,
                                          transaction: t,
                                        ),
                                      ),
                                    );
                                  },
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
