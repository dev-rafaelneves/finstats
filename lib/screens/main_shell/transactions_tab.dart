import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/import_candidate.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/csv_bank_parser.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/export_csv_generator.dart';
import '../../utils/ofx_parser.dart';
import '../../utils/report_pdf_generator.dart';
import '../../widgets/ios_grouped_section.dart';
import '../../widgets/ios_list_tile.dart';
import '../import_reconciliation_screen.dart';
import '../transaction_detail_screen.dart';

class TransactionsTab extends StatefulWidget {
  final AppState appState;
  final VoidCallback onOpenNewTransaction;

  const TransactionsTab({
    super.key,
    required this.appState,
    required this.onOpenNewTransaction,
  });

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSegmentIndex = 0; // 0: Todos, 1: Despesa, 2: Receita, 3: Transferência

  void _showExportImportOptions() {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Dados & Extratos', style: TextStyle(fontWeight: FontWeight.w600)),
        message: const Text('Importe arquivos bancários ou exporte relatórios consolidados.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _importStatement();
            },
            child: const Text('📥 Importar Extrato (OFX / CSV)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportCsv();
            },
            child: const Text('📊 Exportar Planilha CSV / Excel'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportPdf();
            },
            child: const Text('📄 Gerar Relatório Mensal em PDF'),
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

  Future<void> _exportPdf() async {
    final month = widget.appState.selectedMonth;
    final transactions = widget.appState.getMonthTransactions(month);

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma transação encontrada no mês para exportar.')),
      );
      return;
    }

    await ReportPdfGenerator.printOrShareReport(
      userName: widget.appState.userProfile?.name ?? 'Usuário',
      month: month,
      totalIncome: widget.appState.getMonthIncome(month),
      totalExpense: widget.appState.getMonthExpense(month),
      netSavings: widget.appState.getMonthSavings(month),
      transactions: transactions,
      categoryMap: widget.appState.categoryMap,
      accountMap: widget.appState.accountMap,
    );
  }

  Future<void> _exportCsv() async {
    final list = widget.appState.getMonthTransactions(widget.appState.selectedMonth);
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma transação encontrada no mês para exportar.')),
      );
      return;
    }

    HapticFeedback.lightImpact();
    await ExportCsvGenerator.shareCsv(
      transactions: list,
      categoryMap: widget.appState.categoryMap,
      accountMap: widget.appState.accountMap,
      subject: 'Extrato Financeiro ${CurrencyFormatter.formatMonthYear(widget.appState.selectedMonth)}',
    );
  }

  Future<void> _importStatement() async {
    const typeGroup = XTypeGroup(
      label: 'Extratos Bancários',
      extensions: <String>['ofx', 'csv', 'txt'],
    );

    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;

    final content = await file.readAsString();
    final nameLower = file.name.toLowerCase();

    final List<ImportCandidate> candidates;
    final String fileType;

    if (nameLower.endsWith('.ofx')) {
      fileType = 'OFX';
      candidates = OfxParser.parse(
        content,
        availableCategories: widget.appState.categories,
        existingTransactions: widget.appState.transactions,
      );
    } else {
      fileType = 'CSV';
      candidates = CsvBankParser.parse(
        content,
        availableCategories: widget.appState.categories,
        existingTransactions: widget.appState.transactions,
      );
    }

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum lançamento legível encontrado no arquivo.')),
        );
      }
      return;
    }

    if (mounted) {
      final importedCount = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => ImportReconciliationScreen(
            appState: widget.appState,
            initialCandidates: candidates,
            fileName: file.name,
            fileType: fileType,
          ),
        ),
      );

      if (importedCount != null && importedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$importedCount lançamentos importados com sucesso!')),
        );
      }
    }
  }

  String _formatDateGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Hoje';
    if (target == today.subtract(const Duration(days: 1))) return 'Ontem';
    return DateFormat("d 'de' MMMM", 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final selectedMonth = widget.appState.selectedMonth;
    var list = widget.appState.getMonthTransactions(selectedMonth);

    // Apply type filter
    if (_selectedSegmentIndex == 1) {
      list = list.where((t) => t.type == TransactionType.expense).toList();
    } else if (_selectedSegmentIndex == 2) {
      list = list.where((t) => t.type == TransactionType.income).toList();
    } else if (_selectedSegmentIndex == 3) {
      list = list.where((t) => t.type == TransactionType.transfer).toList();
    }

    // Apply search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) => t.description.toLowerCase().contains(query)).toList();
    }

    // Group transactions by date
    final Map<DateTime, List<TransactionItem>> groupedByDate = {};
    for (final t in list) {
      final dayKey = DateTime(t.date.year, t.date.month, t.date.day);
      groupedByDate.putIfAbsent(dayKey, () => []).add(t);
    }
    final sortedDates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

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
                'Extrato',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  color: textPrimary,
                ),
              ),
            ),
            actions: [
              // Botão Importar / Exportar (Ações de Extrato)
              IconButton(
                tooltip: 'Importação / Exportação',
                onPressed: _showExportImportOptions,
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 20, color: AppColors.emeraldDark),
              ),

              // Botão Novo Lançamento (+)
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: IconButton(
                  tooltip: 'Novo Lançamento',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onOpenNewTransaction();
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

          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    // Seletor de Mês (Navegação Rápida)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              widget.appState.setSelectedMonth(
                                DateTime(selectedMonth.year, selectedMonth.month - 1, 1),
                              );
                            },
                            child: const Icon(Icons.chevron_left_rounded, size: 28),
                          ),
                          Text(
                            CurrencyFormatter.formatMonthYear(selectedMonth),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              widget.appState.setSelectedMonth(
                                DateTime(selectedMonth.year, selectedMonth.month + 1, 1),
                              );
                            },
                            child: const Icon(Icons.chevron_right_rounded, size: 28),
                          ),
                        ],
                      ),
                    ),

                    // Barra de Busca iOS Cupertino
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        placeholder: 'Buscar lançamentos...',
                        style: TextStyle(color: textPrimary),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    // Filtro Segmentado iOS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<int>(
                          groupValue: _selectedSegmentIndex,
                          children: const {
                            0: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text('Todos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            1: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text('Despesas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            2: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text('Receitas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            3: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text('Transf.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          },
                          onValueChanged: (val) {
                            if (val != null) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSegmentIndex = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de Transações Agrupadas por Data
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum lançamento encontrado.',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final date = sortedDates[index];
                    final transactionsOnDate = groupedByDate[date]!;
                    final headerTitle = _formatDateGroupHeader(date);

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: IosGroupedSection(
                          header: headerTitle,
                          children: transactionsOnDate.map((t) {
                            final cat = widget.appState.categoryMap[t.categoryId];
                            final acc = widget.appState.accountMap[t.accountId];
                            final isIncome = t.type == TransactionType.income;
                            final isTransfer = t.type == TransactionType.transfer;

                            return IosListTile(
                              icon: cat != null
                                  ? CategoryIconHelper.getIcon(cat.iconName)
                                  : (isTransfer ? Icons.swap_horiz_rounded : Icons.category_rounded),
                              iconBackgroundColor: cat != null
                                  ? Color(cat.colorValue).withValues(alpha: 0.15)
                                  : (isIncome
                                      ? AppColors.emerald.withValues(alpha: 0.15)
                                      : (isTransfer ? AppColors.indigo.withValues(alpha: 0.15) : AppColors.rose.withValues(alpha: 0.15))),
                              iconColor: cat != null
                                  ? Color(cat.colorValue)
                                  : (isIncome ? AppColors.emerald : (isTransfer ? AppColors.indigo : AppColors.rose)),
                              title: t.description,
                              subtitle: '${acc?.name ?? "Conta"}${t.isInstallment ? " • ${t.installmentIndex}/${t.totalInstallments}x" : ""}',
                              showChevron: true,
                              trailing: Text(
                                '${isIncome ? "+" : (isTransfer ? "" : "-")} ${CurrencyFormatter.format(t.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: isIncome
                                      ? AppColors.emeraldDark
                                      : (isTransfer ? AppColors.indigo : AppColors.rose),
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(
                                      appState: widget.appState,
                                      transaction: t,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  childCount: sortedDates.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
