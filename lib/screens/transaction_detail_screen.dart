import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/ios_grouped_section.dart';
import '../widgets/ios_list_tile.dart';

class TransactionDetailScreen extends StatefulWidget {
  final AppState appState;
  final TransactionItem transaction;

  const TransactionDetailScreen({
    super.key,
    required this.appState,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _descController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late String _selectedAccountId;
  late String _selectedCategoryId;
  late bool _isPaid;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(text: widget.transaction.amount.toStringAsFixed(2));
    _notesController = TextEditingController(text: widget.transaction.notes ?? '');
    _selectedDate = widget.transaction.date;
    _selectedAccountId = widget.transaction.accountId;
    _selectedCategoryId = widget.transaction.categoryId;
    _isPaid = widget.transaction.isPaid;
  }

  Future<void> _saveChanges() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.').trim());
    if (amount == null || amount <= 0) return;

    final updated = widget.transaction.copyWith(
      description: _descController.text.trim(),
      amount: amount,
      date: _selectedDate,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      isPaid: _isPaid,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    HapticFeedback.lightImpact();
    await widget.appState.updateTransaction(updated);

    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento atualizado com sucesso!')),
      );
    }
  }

  void _confirmDelete() {
    final isInstallment = widget.transaction.isInstallment && widget.transaction.installmentGroupId != null;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Excluir Lançamento', style: TextStyle(fontWeight: FontWeight.w600)),
        message: const Text('Esta operação não pode ser desfeita.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              HapticFeedback.mediumImpact();
              await widget.appState.deleteTransaction(widget.transaction.id);
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Excluir apenas este lançamento'),
          ),
          if (isInstallment)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(ctx).pop();
                HapticFeedback.mediumImpact();
                await widget.appState.deleteInstallmentGroup(widget.transaction.installmentGroupId!);
                if (mounted) Navigator.of(context).pop();
              },
              child: Text('Excluir todas as ${widget.transaction.totalInstallments} parcelas'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.emeraldDark)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cat = widget.appState.categoryMap[_selectedCategoryId];
    final acc = widget.appState.accountMap[_selectedAccountId];
    final isExpense = widget.transaction.type == TransactionType.expense;
    final isIncome = widget.transaction.type == TransactionType.income;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded),
            tooltip: _isEditing ? 'Salvar' : 'Editar',
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose),
            tooltip: 'Excluir',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              // Header Visual do Valor
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cat != null
                            ? Color(cat.colorValue).withValues(alpha: 0.15)
                            : AppColors.indigo.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat != null ? CategoryIconHelper.getIcon(cat.iconName) : Icons.receipt_rounded,
                        size: 28,
                        color: cat != null ? Color(cat.colorValue) : AppColors.indigo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: CupertinoTextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text('R\$ ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          ),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isExpense ? AppColors.rose : (isIncome ? AppColors.emeraldDark : AppColors.indigo),
                          ),
                        ),
                      )
                    else
                      Text(
                        '${isIncome ? "+" : (isExpense ? "-" : "")} ${CurrencyFormatter.format(widget.transaction.amount)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          color: isExpense ? AppColors.rose : (isIncome ? AppColors.emeraldDark : AppColors.indigo),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Status Chip Apple
                    InkWell(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await widget.appState.toggleTransactionPaid(widget.transaction.id);
                        setState(() => _isPaid = !_isPaid);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isPaid
                              ? AppColors.emerald.withValues(alpha: 0.15)
                              : AppColors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                              size: 14,
                              color: _isPaid ? AppColors.emeraldDark : AppColors.amber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isPaid ? 'Consolidado / Pago' : 'Pendente (Toque para liquidar)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isPaid ? AppColors.emeraldDark : AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seção Inset Grouped de Informações
              IosGroupedSection(
                header: 'Informações do Lançamento',
                children: _isEditing
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: CupertinoTextField(
                            controller: _descController,
                            placeholder: 'Descrição',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Conta:'),
                              DropdownButton<String>(
                                value: _selectedAccountId,
                                underline: const SizedBox.shrink(),
                                items: widget.appState.accounts.map((a) {
                                  return DropdownMenuItem(value: a.id, child: Text(a.name));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedAccountId = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Categoria:'),
                              DropdownButton<String>(
                                value: _selectedCategoryId,
                                underline: const SizedBox.shrink(),
                                items: widget.appState.categories.map((c) {
                                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategoryId = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: CupertinoTextField(
                            controller: _notesController,
                            placeholder: 'Anotações / Observações',
                            maxLines: 2,
                          ),
                        ),
                      ]
                    : [
                        IosListTile(
                          title: 'Descrição',
                          trailing: Text(widget.transaction.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        IosListTile(
                          title: 'Conta',
                          trailing: Text(acc?.name ?? 'Conta', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        IosListTile(
                          title: 'Categoria',
                          trailing: Text(cat?.name ?? 'Categoria', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        IosListTile(
                          title: 'Data',
                          trailing: Text(CurrencyFormatter.formatDate(widget.transaction.date)),
                        ),
                        if (widget.transaction.isInstallment)
                          IosListTile(
                            title: 'Parcelamento',
                            trailing: Text('Parcela ${widget.transaction.installmentIndex} de ${widget.transaction.totalInstallments}'),
                          ),
                        if (widget.transaction.isRecurring)
                          const IosListTile(
                            title: 'Recorrência',
                            trailing: Text('Despesa Fixa Mensal'),
                          ),
                        if (widget.transaction.notes != null && widget.transaction.notes!.isNotEmpty)
                          IosListTile(
                            title: 'Observações',
                            subtitle: widget.transaction.notes,
                          ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
