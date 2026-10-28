import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/import_candidate.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class ImportReconciliationScreen extends StatefulWidget {
  final AppState appState;
  final List<ImportCandidate> initialCandidates;
  final String fileName;
  final String fileType; // 'OFX' ou 'CSV'

  const ImportReconciliationScreen({
    super.key,
    required this.appState,
    required this.initialCandidates,
    required this.fileName,
    required this.fileType,
  });

  @override
  State<ImportReconciliationScreen> createState() => _ImportReconciliationScreenState();
}

class _ImportReconciliationScreenState extends State<ImportReconciliationScreen> {
  late List<ImportCandidate> _candidates;
  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _candidates = List.from(widget.initialCandidates);
    if (widget.appState.accounts.isNotEmpty) {
      _selectedAccountId = widget.appState.accounts.first.id;
    }
  }

  void _selectAll(bool select) {
    HapticFeedback.lightImpact();
    setState(() {
      for (final c in _candidates) {
        c.isSelected = select;
      }
    });
  }

  void _deselectDuplicates() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final c in _candidates) {
        if (c.isDuplicate) {
          c.isSelected = false;
        }
      }
    });
  }

  Future<void> _commitImport() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma conta de destino.')),
      );
      return;
    }

    final selectedCount = _candidates.where((c) => c.isSelected).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum lançamento selecionado para importação.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final imported = await widget.appState.importTransactionsInBatch(
      candidates: _candidates,
      accountId: _selectedAccountId!,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(imported);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final selectedCount = _candidates.where((c) => c.isSelected).length;
    final duplicateCount = _candidates.where((c) => c.isDuplicate).length;

    final selectedTotal = _candidates.where((c) => c.isSelected).fold(0.0, (sum, c) {
      return sum + (c.type == TransactionType.income ? c.amount : -c.amount);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Conciliação • ${widget.fileType}'),
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.fileType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.indigo),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.fileName,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Seletor de Conta de Destino
                DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Conta de Destino para Importação',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: widget.appState.accounts.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                ),
                const SizedBox(height: 12),

                // Resumo de Seleção e Conciliação
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$selectedCount de ${_candidates.length} selecionados',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    Text(
                      'Impacto: ${selectedTotal >= 0 ? "+" : ""}${CurrencyFormatter.format(selectedTotal)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selectedTotal >= 0 ? AppColors.emeraldDark : AppColors.rose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Action chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('Selecionar Todos', style: TextStyle(fontSize: 11)),
                        onPressed: () => _selectAll(true),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('Desmarcar Todos', style: TextStyle(fontSize: 11)),
                        onPressed: () => _selectAll(false),
                      ),
                      if (duplicateCount > 0) ...[
                        const SizedBox(width: 6),
                        ActionChip(
                          avatar: const Icon(Icons.filter_alt_off_outlined, size: 14, color: AppColors.amber),
                          label: Text(
                            'Desmarcar $duplicateCount duplicados',
                            style: const TextStyle(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _deselectDuplicates,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

          // Lista de Candidatos para Conciliação
          Expanded(
            child: _candidates.isEmpty
                ? const Center(child: Text('Nenhum lançamento identificado no arquivo.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final c = _candidates[i];
                      final isIncome = c.type == TransactionType.income;
                      final availableCats = widget.appState.categories.where((cat) => cat.type == c.type).toList();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: c.isDuplicate
                                ? AppColors.amber.withValues(alpha: 0.5)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: c.isDuplicate ? 1.2 : 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: c.isSelected,
                                  activeColor: AppColors.emeraldDark,
                                  onChanged: (val) {
                                    setState(() => c.isSelected = val ?? false);
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.description,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.formatDate(c.date),
                                        style: TextStyle(fontSize: 11, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isIncome ? "+" : "-"} ${CurrencyFormatter.format(c.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isIncome ? AppColors.emeraldDark : AppColors.rose,
                                  ),
                                ),
                              ],
                            ),

                            // Alerta de duplicidade se encontrado no banco
                            if (c.isDuplicate) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.amber),
                                    SizedBox(width: 4),
                                    Text(
                                      'Provável duplicata (já existe no extrato com data e valor idênticos)',
                                      style: TextStyle(fontSize: 10, color: AppColors.amber, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Seletor de Categoria
                            Row(
                              children: [
                                const Text('Categoria: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: availableCats.any((cat) => cat.id == c.categoryId)
                                        ? c.categoryId
                                        : (availableCats.isNotEmpty ? availableCats.first.id : null),
                                    isExpanded: true,
                                    underline: const SizedBox.shrink(),
                                    style: TextStyle(fontSize: 12, color: textPrimary),
                                    items: availableCats.map((cat) {
                                      return DropdownMenuItem(
                                        value: cat.id,
                                        child: Row(
                                          children: [
                                            Icon(
                                              CategoryIconHelper.getIcon(cat.iconName),
                                              size: 14,
                                              color: Color(cat.colorValue),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(cat.name),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => c.categoryId = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.8)),
        ),
        child: ElevatedButton.icon(
          onPressed: _isSaving || selectedCount == 0 ? null : _commitImport,
          icon: _isSaving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.file_download_done_rounded),
          label: Text(
            _isSaving ? 'Importando...' : 'Confirmar Importação ($selectedCount)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emeraldDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
