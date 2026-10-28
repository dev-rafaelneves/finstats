import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/ios_grouped_section.dart';
import '../widgets/ios_list_tile.dart';
import 'transaction_detail_screen.dart';

class CreditCardsScreen extends StatelessWidget {
  final AppState appState;

  const CreditCardsScreen({super.key, required this.appState});

  void _showPayInvoiceModal(BuildContext context, CreditCardInvoice invoice) {
    String? selectedDebitAccountId = appState.bankAccounts.isNotEmpty
        ? appState.bankAccounts.first.id
        : null;

    final amountController = TextEditingController(
      text: invoice.totalAmount.toStringAsFixed(2),
    );

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
                        'Pagar Fatura',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          if (selectedDebitAccountId == null) return;
                          final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
                          if (amount == null || amount <= 0) return;

                          Navigator.of(ctx).pop();
                          HapticFeedback.mediumImpact();

                          await appState.payCreditCardInvoice(
                            cardId: invoice.card.id,
                            debitAccountId: selectedDebitAccountId!,
                            amount: amount,
                            paymentDate: DateTime.now(),
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fatura liquidada com sucesso!')),
                            );
                          }
                        },
                        child: const Text(
                          'Pagar',
                          style: TextStyle(color: AppColors.emeraldDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cartão: ${invoice.card.name}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('R\$ ', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    placeholder: '0,00',
                  ),
                  const SizedBox(height: 16),
                  const Text('Conta de débito:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: appState.bankAccounts.map((acc) {
                        final isSelected = acc.id == selectedDebitAccountId;
                        return InkWell(
                          onTap: () => setState(() => selectedDebitAccountId = acc.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  color: isSelected ? AppColors.emeraldDark : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(acc.name)),
                                Text(
                                  CurrencyFormatter.format(acc.currentBalance),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCardModal(BuildContext context) {
    final nameController = TextEditingController();
    final limitController = TextEditingController();
    int closingDay = 20;
    int dueDay = 28;

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
                        'Novo Cartão',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          final limit = double.tryParse(limitController.text.replaceAll(',', '.')) ?? 1000.0;

                          Navigator.of(ctx).pop();
                          HapticFeedback.mediumImpact();

                          final newCard = Account(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            type: AccountType.creditCard,
                            creditLimit: limit,
                            closingDay: closingDay,
                            dueDay: dueDay,
                            colorValue: 0xFF8B5CF6,
                            iconName: 'credit_card',
                          );

                          await appState.addAccount(newCard);
                        },
                        child: const Text(
                          'Adicionar',
                          style: TextStyle(color: AppColors.emeraldDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: nameController,
                    placeholder: 'Nome do Cartão (ex: Nubank, Apple Card)',
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('Limite: R\$ ', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    placeholder: '0,00',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dia de Corte / Fechamento:', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              onPressed: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (_) => Container(
                                    height: 200,
                                    color: surfaceColor,
                                    child: CupertinoPicker(
                                      itemExtent: 32,
                                      scrollController: FixedExtentScrollController(initialItem: closingDay - 1),
                                      onSelectedItemChanged: (i) => setState(() => closingDay = i + 1),
                                      children: List.generate(31, (i) => Center(child: Text('Dia ${i + 1}'))),
                                    ),
                                  ),
                                );
                              },
                              child: Text('Dia $closingDay', style: TextStyle(color: textPrimary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dia de Vencimento:', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      ),
                    ],
                  ),
                ],
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

    final cards = appState.creditCards;

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
                'Cartões & Faturas',
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
                  tooltip: 'Adicionar Cartão',
                  onPressed: () => _showAddCardModal(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.emeraldDark,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                ),
              ),
            ],
          ),

          if (cards.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.credit_card_off_rounded, size: 48, color: textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum cartão cadastrado.',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      color: AppColors.emeraldDark,
                      onPressed: () => _showAddCardModal(context),
                      child: const Text('Cadastrar Cartão'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final card = cards[i];
                    final invoice = appState.getCardInvoice(card, appState.selectedMonth);
                    final limit = card.creditLimit ?? 0.0;
                    final available = card.availableLimit;
                    final used = limit - available;
                    final usedPct = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Apple Wallet Card (Pass)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // EMV Chip Simulation
                                      Container(
                                        width: 38,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFB89628), width: 1),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Fatura ${invoice.status.label}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    card.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(invoice.totalAmount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Melhor dia: ${invoice.bestPurchaseDay}',
                                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Vencimento: ${CurrencyFormatter.formatDate(invoice.dueDate)}',
                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Inset Grouped Section do Cartão
                            IosGroupedSection(
                              header: 'Status de Limite',
                              children: [
                                IosListTile(
                                  title: 'Limite Disponível',
                                  trailing: Text(
                                    CurrencyFormatter.format(available),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                  ),
                                ),
                                IosListTile(
                                  title: 'Limite Total',
                                  trailing: Text(CurrencyFormatter.format(limit)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: usedPct,
                                          minHeight: 5,
                                          backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                          valueColor: AlwaysStoppedAnimation(
                                            usedPct > 0.85 ? AppColors.rose : AppColors.indigo,
                                          ),
                                        ),
                                      ),
                                      if (invoice.totalAmount > 0 && invoice.status != InvoiceStatus.paid) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: CupertinoButton(
                                            color: AppColors.emeraldDark,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            onPressed: () => _showPayInvoiceModal(context, invoice),
                                            child: const Text('Pagar Fatura', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Lançamentos do Ciclo
                            if (invoice.items.isNotEmpty)
                              IosGroupedSection(
                                header: 'Lançamentos desta Fatura (${invoice.items.length})',
                                children: invoice.items.map((item) {
                                  return IosListTile(
                                    title: item.description,
                                    subtitle: CurrencyFormatter.formatDateShort(item.date),
                                    trailing: Text(
                                      CurrencyFormatter.format(item.amount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.rose),
                                    ),
                                    showChevron: true,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TransactionDetailScreen(
                                            appState: appState,
                                            transaction: item,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: cards.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
