import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/ios_grouped_section.dart';
import '../widgets/ios_list_tile.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  final AppState appState;
  static const _uuid = Uuid();

  const RecurringTransactionsScreen({super.key, required this.appState});

  void _showAddRuleModal(BuildContext context) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType type = TransactionType.expense;
    int dueDay = 10;
    String? selectedAccountId = appState.accounts.isNotEmpty ? appState.accounts.first.id : null;
    String? selectedCategoryId = appState.categories.isNotEmpty ? appState.categories.first.id : null;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return Container(
            color: surfaceColor,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 16,
              left: 20,
              right: 20,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar', style: TextStyle(color: AppColors.rose)),
                        ),
                        Text(
                          'Nova Conta Fixa',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final desc = descController.text.trim();
                            final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
                            if (desc.isEmpty || amount == null || amount <= 0 || selectedAccountId == null || selectedCategoryId == null) {
                              return;
                            }

                            Navigator.of(ctx).pop();
                            HapticFeedback.mediumImpact();

                            final rule = RecurringRule(
                              id: _uuid.v4(),
                              description: desc,
                              amount: amount,
                              type: type,
                              categoryId: selectedCategoryId,
                              accountId: selectedAccountId,
                              dueDay: dueDay,
                              createdAt: DateTime.now(),
                            );

                            await appState.addRecurringRule(rule);
                          },
                          child: const Text(
                            'Salvar',
                            style: TextStyle(color: AppColors.emeraldDark, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CupertinoSlidingSegmentedControl<TransactionType>(
                      groupValue: type,
                      children: const {
                        TransactionType.expense: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Text('Despesa Fixa', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        TransactionType.income: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Text('Receita Fixa', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null) setState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    CupertinoTextField(
                      controller: descController,
                      placeholder: 'Descrição (ex: Aluguel, Internet, Salário)',
                    ),
                    const SizedBox(height: 10),
                    CupertinoTextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('R\$ ', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      placeholder: '0,00',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Dia do Vencimento:', style: TextStyle(fontSize: 13)),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          onPressed: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (_) => Container(
                                height: 200,
                                color: surfaceColor,
                                child: CupertinoPicker(
                                  itemExtent: 32,
                                  scrollController: FixedExtentScrollController(initialItem: dueDay - 1),
                                  onSelectedItemChanged: (i) => setState(() => dueDay = i + 1),
                                  children: List.generate(31, (i) => Center(child: Text('Dia ${i + 1}'))),
                                ),
                              ),
                            );
                          },
                          child: Text('Dia $dueDay', style: TextStyle(color: textPrimary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final rules = appState.recurringRules;

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
                'Contas Fixas',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  color: textPrimary,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  tooltip: 'Nova Regra',
                  onPressed: () => _showAddRuleModal(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.emeraldDark,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                ),
              ),
            ],
          ),

          if (rules.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_repeat_rounded, size: 48, color: textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma conta recorrente cadastrada.',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      color: AppColors.emeraldDark,
                      onPressed: () => _showAddRuleModal(context),
                      child: const Text('Cadastrar Conta Fixa'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: IosGroupedSection(
                      header: 'Assinaturas & Despesas Recorrentes (${rules.length})',
                      footer: 'Lançamentos gerados automaticamente a cada ciclo mensal.',
                      children: rules.map((rule) {
                        final cat = appState.categoryMap[rule.categoryId];
                        final isIncome = rule.type == TransactionType.income;

                        return IosListTile(
                          icon: cat != null ? CategoryIconHelper.getIcon(cat.iconName) : Icons.repeat_rounded,
                          iconBackgroundColor: cat != null
                              ? Color(cat.colorValue).withValues(alpha: 0.15)
                              : AppColors.indigo.withValues(alpha: 0.15),
                          iconColor: cat != null ? Color(cat.colorValue) : AppColors.indigo,
                          title: rule.description,
                          subtitle: 'Todo dia ${rule.dueDay} • ${isIncome ? "Receita" : "Despesa"}',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyFormatter.format(rule.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: isIncome ? AppColors.emeraldDark : AppColors.rose,
                                ),
                              ),
                              const SizedBox(width: 10),
                              CupertinoSwitch(
                                value: rule.isActive,
                                activeTrackColor: AppColors.emeraldDark,
                                onChanged: (_) async {
                                  HapticFeedback.lightImpact();
                                  await appState.toggleRecurringRule(rule.id);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
