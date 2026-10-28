import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'ios_grouped_section.dart';

class QuickTransactionModal extends StatefulWidget {
  final AppState appState;

  const QuickTransactionModal({super.key, required this.appState});

  static Future<void> show(BuildContext context, {required AppState appState}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickTransactionModal(appState: appState),
    );
  }

  @override
  State<QuickTransactionModal> createState() => _QuickTransactionModalState();
}

class _QuickTransactionModalState extends State<QuickTransactionModal> {
  TransactionType _type = TransactionType.expense;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedDestAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  int _installments = 1;

  @override
  void initState() {
    super.initState();
    if (widget.appState.accounts.isNotEmpty) {
      _selectedAccountId = widget.appState.accounts.first.id;
      if (widget.appState.accounts.length > 1) {
        _selectedDestAccountId = widget.appState.accounts[1].id;
      }
    }

    _updateDefaultCategory();
  }

  void _updateDefaultCategory() {
    final availableCats = widget.appState.categories.where((c) {
      if (_type == TransactionType.transfer) return c.id == 'cat_transfer';
      return c.type == _type;
    }).toList();

    if (availableCats.isNotEmpty) {
      _selectedCategoryId = availableCats.first.id;
    }
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira um valor válido maior que zero.')),
      );
      return;
    }

    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma descrição.')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma conta.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    await widget.appState.addTransaction(
      accountId: _selectedAccountId!,
      destinationAccountId: _type == TransactionType.transfer ? _selectedDestAccountId : null,
      categoryId: _selectedCategoryId ?? 'cat_transfer',
      description: _descController.text.trim(),
      amount: amount,
      date: _selectedDate,
      type: _type,
      totalInstallments: _type == TransactionType.expense ? _installments : 1,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showDatePickerModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          height: 260,
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
                    const Text('Data do Lançamento', style: TextStyle(fontWeight: FontWeight.w600)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK', style: TextStyle(color: AppColors.emeraldDark, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2035),
                  onDateTimeChanged: (date) {
                    setState(() => _selectedDate = date);
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
    final surfaceColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final categories = widget.appState.categories.where((c) {
      if (_type == TransactionType.transfer) return c.id == 'cat_transfer';
      return c.type == _type;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // iOS Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // iOS Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.rose, fontSize: 16),
                      ),
                    ),
                    Text(
                      'Novo Lançamento',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _submit,
                      child: const Text(
                        'Salvar',
                        style: TextStyle(
                          color: AppColors.emeraldDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Control (Despesa / Receita / Transferência)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoSlidingSegmentedControl<TransactionType>(
                  groupValue: _type,
                  children: const {
                    TransactionType.expense: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('Despesa', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    TransactionType.income: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('Receita', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    TransactionType.transfer: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('Transferência', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _type = val;
                        _updateDefaultCategory();
                      });
                    }
                  },
                ),
              ),

              // Amount Input Apple Style (Grande e em destaque)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'R\$ ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _type == TransactionType.expense
                            ? AppColors.rose
                            : (_type == TransactionType.income ? AppColors.emeraldDark : AppColors.indigo),
                      ),
                    ),
                    IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 100, maxWidth: 240),
                        child: CupertinoTextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
                          placeholder: '0,00',
                          placeholderStyle: TextStyle(
                            color: textSecondary.withValues(alpha: 0.35),
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: -1,
                          ),
                          decoration: const BoxDecoration(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Formulário em Inset Grouped Section
              IosGroupedSection(
                header: 'Detalhes da Movimentação',
                children: [
                  // Descrição
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: CupertinoTextField(
                      controller: _descController,
                      prefix: Icon(Icons.edit_note_rounded, size: 20, color: textSecondary),
                      placeholder: 'Descrição (ex: Supermercado, Aluguel)',
                      style: TextStyle(color: textPrimary),
                      decoration: const BoxDecoration(),
                    ),
                  ),

                  // Conta Origem
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Conta Origem', style: TextStyle(fontSize: 15, color: textPrimary)),
                        DropdownButton<String>(
                          value: _selectedAccountId,
                          underline: const SizedBox.shrink(),
                          items: widget.appState.accounts.map((a) {
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAccountId = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Conta Destino (se transferência)
                  if (_type == TransactionType.transfer) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Conta Destino', style: TextStyle(fontSize: 15, color: textPrimary)),
                          DropdownButton<String>(
                            value: _selectedDestAccountId,
                            underline: const SizedBox.shrink(),
                            items: widget.appState.accounts.map((a) {
                              return DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDestAccountId = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Data
                  InkWell(
                    onTap: _showDatePickerModal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Data', style: TextStyle(fontSize: 15, color: textPrimary)),
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.formatDate(_selectedDate),
                                style: const TextStyle(color: AppColors.emeraldDark, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: textSecondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Parcelamento (se despesa)
                  if (_type == TransactionType.expense) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Parcelamento', style: TextStyle(fontSize: 15, color: textPrimary)),
                          DropdownButton<int>(
                            value: _installments,
                            underline: const SizedBox.shrink(),
                            items: [1, 2, 3, 4, 5, 6, 10, 12, 18, 24].map((n) {
                              return DropdownMenuItem(
                                value: n,
                                child: Text(
                                  n == 1 ? 'À vista (1x)' : '$n x',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _installments = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Seletor de Categorias
              if (_type != TransactionType.transfer) ...[
                IosGroupedSection(
                  header: 'Categoria',
                  contentPadding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = cat.id == _selectedCategoryId;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CategoryIconHelper.getIcon(cat.iconName),
                              size: 14,
                              color: isSelected ? Colors.white : Color(cat.colorValue),
                            ),
                            const SizedBox(width: 4),
                            Text(cat.name),
                          ],
                        ),
                        selectedColor: Color(cat.colorValue),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategoryId = cat.id);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Observações Opcionais
              IosGroupedSection(
                header: 'Anotações (Opcional)',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: CupertinoTextField(
                    controller: _notesController,
                    placeholder: 'Ex: comprado com desconto à vista',
                    maxLines: 2,
                    decoration: const BoxDecoration(),
                    style: TextStyle(color: textPrimary, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
