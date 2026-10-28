import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import 'currency_formatter.dart';

class ReportPdfGenerator {
  static Future<Uint8List> generateMonthlyReport({
    required String userName,
    required DateTime month,
    required double totalIncome,
    required double totalExpense,
    required double netSavings,
    required List<TransactionItem> transactions,
    required Map<String, Category> categoryMap,
    required Map<String, Account> accountMap,
  }) async {
    final pdf = pw.Document();
    final monthTitle = DateFormat('MMMM yyyy', 'pt_BR').format(month).toUpperCase();
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

    // Agregação por Categoria
    final categoryTotals = <String, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] ?? 0.0) + t.amount;
      }
    }
    final sortedCategoryTotals = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Agregação por Conta / Meio de Pagamento
    final accountTotals = <String, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        accountTotals[t.accountId] = (accountTotals[t.accountId] ?? 0.0) + t.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RELATÓRIO FINANCEIRO CONSOLIDADO',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Competência: $monthTitle',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      userName,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.Text(
                      'Emissão: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Summary Cards Row
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildMetricCard(
                    'Total Receitas',
                    CurrencyFormatter.format(totalIncome),
                    PdfColors.green700,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildMetricCard(
                    'Total Despesas',
                    CurrencyFormatter.format(totalExpense),
                    PdfColors.red700,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildMetricCard(
                    'Resultado Líquido',
                    CurrencyFormatter.format(netSavings),
                    netSavings >= 0 ? PdfColors.green800 : PdfColors.red800,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildMetricCard(
                    'Taxa de Poupança',
                    '${savingsRate.toStringAsFixed(1)}%',
                    savingsRate >= 15 ? PdfColors.green700 : (savingsRate >= 0 ? PdfColors.amber700 : PdfColors.red700),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Seção de Análise por Meio de Pagamento & Categorias
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Categorias
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Distribuição de Gastos por Categoria',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                      ),
                      pw.SizedBox(height: 6),
                      pw.TableHelper.fromTextArray(
                        headers: ['Categoria', 'Valor', '% Total'],
                        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                        cellStyle: const pw.TextStyle(fontSize: 8),
                        data: sortedCategoryTotals.map((e) {
                          final catName = categoryMap[e.key]?.name ?? 'Geral';
                          final pct = totalExpense > 0 ? (e.value / totalExpense) * 100 : 0.0;
                          return [catName, CurrencyFormatter.format(e.value), '${pct.toStringAsFixed(1)}%'];
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                // Contas / Meios
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Gastos por Conta / Cartão',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                      ),
                      pw.SizedBox(height: 6),
                      pw.TableHelper.fromTextArray(
                        headers: ['Conta / Cartão', 'Total'],
                        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
                        cellStyle: const pw.TextStyle(fontSize: 8),
                        data: accountTotals.entries.map((e) {
                          final accName = accountMap[e.key]?.name ?? 'Conta';
                          return [accName, CurrencyFormatter.format(e.value)];
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Section Header
            pw.Text(
              'Extrato Detalhado de Lançamentos (${transactions.length})',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 6),

            // Table of transactions
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Descrição', 'Categoria', 'Conta', 'Status', 'Valor'],
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              data: transactions.map((t) {
                final catName = categoryMap[t.categoryId]?.name ?? 'Geral';
                final accName = accountMap[t.accountId]?.name ?? 'Conta';
                final sign = t.type == TransactionType.income ? '+' : (t.type == TransactionType.expense ? '-' : '');
                final formattedValue = '$sign ${CurrencyFormatter.format(t.amount)}';
                final statusStr = t.isPaid ? 'Pago' : 'Pendente';

                return [
                  DateFormat('dd/MM/yyyy').format(t.date),
                  t.description + (t.isInstallment ? ' (${t.installmentIndex}/${t.totalInstallments})' : ''),
                  catName,
                  accName,
                  statusStr,
                  formattedValue,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricCard(String title, String value, PdfColor valueColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printOrShareReport({
    required String userName,
    required DateTime month,
    required double totalIncome,
    required double totalExpense,
    required double netSavings,
    required List<TransactionItem> transactions,
    required Map<String, Category> categoryMap,
    required Map<String, Account> accountMap,
  }) async {
    final pdfBytes = await generateMonthlyReport(
      userName: userName,
      month: month,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      transactions: transactions,
      categoryMap: categoryMap,
      accountMap: accountMap,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'relatorio_financeiro_${DateFormat('yyyy_MM').format(month)}.pdf',
    );
  }
}
