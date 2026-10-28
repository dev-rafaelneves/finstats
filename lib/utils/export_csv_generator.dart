import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class ExportCsvGenerator {
  static String generateCsv({
    required List<TransactionItem> transactions,
    required Map<String, Category> categoryMap,
    required Map<String, Account> accountMap,
  }) {
    final buffer = StringBuffer();

    // UTF-8 BOM para garantir acentuação correta no Microsoft Excel
    buffer.write('\uFEFF');

    // Header
    buffer.writeln('Data;Tipo;Descrição;Categoria;Conta;Valor (R\$);Status;Parcelamento;Observações');

    for (final tx in transactions) {
      final dateStr = DateFormat('dd/MM/yyyy').format(tx.date);
      final typeStr = tx.type.label;
      final desc = tx.description.replaceAll(';', ' - ');
      final cat = categoryMap[tx.categoryId]?.name ?? 'Geral';
      final acc = accountMap[tx.accountId]?.name ?? 'Conta';
      final valueStr = tx.amount.toStringAsFixed(2).replaceAll('.', ',');
      final statusStr = tx.isPaid ? 'Pago / Consolidado' : 'Pendente';
      final installmentStr = tx.isInstallment ? '${tx.installmentIndex}/${tx.totalInstallments}' : 'À vista';
      final notes = (tx.notes ?? '').replaceAll(';', ' - ').replaceAll('\n', ' ');

      buffer.writeln('$dateStr;$typeStr;$desc;$cat;$acc;$valueStr;$statusStr;$installmentStr;$notes');
    }

    return buffer.toString();
  }

  static Future<void> shareCsv({
    required List<TransactionItem> transactions,
    required Map<String, Category> categoryMap,
    required Map<String, Account> accountMap,
    String? subject,
  }) async {
    final csvContent = generateCsv(
      transactions: transactions,
      categoryMap: categoryMap,
      accountMap: accountMap,
    );
    final fileName = 'extrato_financeiro_${DateTime.now().millisecondsSinceEpoch}.csv';
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
      subject: subject ?? 'Extrato Financeiro CSV',
      text: 'Extrato financeiro exportado em formato CSV compatível com Excel e Contabilidade.',
    );
  }
}
