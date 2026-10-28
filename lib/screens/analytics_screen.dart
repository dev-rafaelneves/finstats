import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/cash_flow_evolution_chart.dart';
import '../widgets/financial_health_insight_card.dart';
import '../widgets/ios_grouped_section.dart';
import '../widgets/ios_list_tile.dart';
import 'monthly_comparator_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  final AppState appState;

  const AnalyticsScreen({super.key, required this.appState});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _monthsCount = 6;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final history = widget.appState.getHistoricalMonths(count: _monthsCount);
    final categoryExpenses = widget.appState.getCategoryExpenses(widget.appState.selectedMonth);
    final totalExpense = categoryExpenses.values.fold(0.0, (sum, v) => sum + v);

    final sortedCatEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                'Inteligência Financeira',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: textPrimary,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: const Icon(Icons.compare_arrows_rounded),
                  tooltip: 'Comparador Mês a Mês',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MonthlyComparatorScreen(appState: widget.appState),
                      ),
                    );
                  },
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
                      // Banner Apple Grouped para Comparador Mensal
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MonthlyComparatorScreen(appState: widget.appState),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.indigo.withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 28),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comparador Mês a Mês',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Compare receitas, despesas e categorias entre dois períodos.',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Card de Saúde Financeira
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: FinancialHealthInsightCard(appState: widget.appState),
                      ),

                      // Gráfico de Fluxo de Caixa (fl_chart) em Inset Grouped Section
                      IosGroupedSection(
                        header: 'Evolução do Fluxo de Caixa',
                        footer: 'Barra azul: Receitas • Barra vermelha: Despesas • Linha: Saldo acumulado',
                        contentPadding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoSlidingSegmentedControl<int>(
                                groupValue: _monthsCount,
                                children: const {
                                  6: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    child: Text('6 Meses', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  12: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    child: Text('12 Meses', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                },
                                onValueChanged: (val) {
                                  if (val != null) setState(() => _monthsCount = val);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            CashFlowEvolutionChart(history: history),
                          ],
                        ),
                      ),

                      // Detalhamento de Categorias no Mês Selecionado
                      IosGroupedSection(
                        header: 'Detalhamento por Categoria • ${CurrencyFormatter.formatMonthYear(widget.appState.selectedMonth)}',
                        children: sortedCatEntries.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Text('Nenhuma despesa para detalhar.', style: TextStyle(color: textSecondary)),
                                  ),
                                ),
                              ]
                            : sortedCatEntries.map((entry) {
                                final cat = widget.appState.categoryMap[entry.key];
                                final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                                return IosListTile(
                                  icon: cat != null ? CategoryIconHelper.getIcon(cat.iconName) : Icons.category_rounded,
                                  iconBackgroundColor: cat != null
                                      ? Color(cat.colorValue).withValues(alpha: 0.15)
                                      : AppColors.indigo.withValues(alpha: 0.15),
                                  iconColor: cat != null ? Color(cat.colorValue) : AppColors.indigo,
                                  title: cat?.name ?? 'Geral',
                                  subtitle: '${pct.toStringAsFixed(1)}% do total gasto',
                                  trailing: Text(
                                    CurrencyFormatter.format(entry.value),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.rose),
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
