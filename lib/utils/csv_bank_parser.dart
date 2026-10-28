import 'package:uuid/uuid.dart';
import '../models/import_candidate.dart';
import '../models/models.dart';
import 'ofx_parser.dart';

class CsvBankParser {
  static const _uuid = Uuid();

  static List<ImportCandidate> parse(
    String content, {
    required List<Category> availableCategories,
    required List<TransactionItem> existingTransactions,
  }) {
    final candidates = <ImportCandidate>[];
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();

    if (lines.length < 2) return [];

    // Detecta delimitador (, ou ;)
    final firstLine = lines.first;
    final separator = firstLine.contains(';') ? ';' : ',';

    final headers = firstLine.split(separator).map((h) => h.trim().toLowerCase().replaceAll('"', '')).toList();

    int dateIdx = -1;
    int descIdx = -1;
    int amountIdx = -1;

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (h.contains('data') || h.contains('date')) {
        dateIdx = i;
      } else if (h.contains('descri') || h.contains('hist') || h.contains('memo') || h.contains('title') || h.contains('identificador')) {
        descIdx = i;
      } else if (h.contains('valor') || h.contains('amount') || h.contains('quantia')) {
        amountIdx = i;
      }
    }

    // Se não encontrou índices por cabeçalho, assume padrão (0: data, 1: desc, 2: valor)
    if (dateIdx == -1) dateIdx = 0;
    if (descIdx == -1 && headers.length > 1) descIdx = 1;
    if (amountIdx == -1 && headers.length > 2) amountIdx = 2;

    final defaultExpenseCat = availableCategories.firstWhere(
      (c) => c.type == TransactionType.expense,
      orElse: () => availableCategories.first,
    );

    final defaultIncomeCat = availableCategories.firstWhere(
      (c) => c.type == TransactionType.income,
      orElse: () => availableCategories.first,
    );

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final cols = _splitCsvLine(line, separator);
      if (cols.length <= amountIdx || cols.length <= descIdx || cols.length <= dateIdx) continue;

      final dateStr = cols[dateIdx].replaceAll('"', '').trim();
      final descStr = cols[descIdx].replaceAll('"', '').trim();
      final amountStr = cols[amountIdx].replaceAll('"', '').trim();

      if (amountStr.isEmpty) continue;

      final parsedAmount = _parseAmount(amountStr);
      if (parsedAmount == 0.0) continue;

      final absAmount = parsedAmount.abs();
      final isIncome = parsedAmount > 0;
      final type = isIncome ? TransactionType.income : TransactionType.expense;
      final date = _parseCsvDate(dateStr);

      final suggestedCat = OfxParser.guessCategory(
        descStr,
        type,
        availableCategories,
        type == TransactionType.income ? defaultIncomeCat : defaultExpenseCat,
      );

      final isDuplicate = existingTransactions.any((t) {
        final sameAmount = (t.amount - absAmount).abs() < 0.01;
        final sameDay = t.date.year == date.year && t.date.month == date.month && t.date.day == date.day;
        final sameDesc = t.description.toLowerCase().contains(descStr.toLowerCase()) ||
            descStr.toLowerCase().contains(t.description.toLowerCase());
        return sameAmount && sameDay && sameDesc;
      });

      candidates.add(
        ImportCandidate(
          id: _uuid.v4(),
          description: descStr.isEmpty ? 'Lançamento' : descStr,
          amount: absAmount,
          date: date,
          type: type,
          isDuplicate: isDuplicate,
          isSelected: !isDuplicate,
          categoryId: suggestedCat.id,
        ),
      );
    }

    return candidates;
  }

  static List<String> _splitCsvLine(String line, String separator) {
    return line.split(separator).map((s) => s.trim()).toList();
  }

  static double _parseAmount(String str) {
    var cleaned = str.replaceAll('R\$', '').replaceAll(' ', '').trim();
    if (cleaned.contains(',') && cleaned.contains('.')) {
      // Formato brasileiro: 1.250,50
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '.');
    }
    return double.tryParse(cleaned) ?? 0.0;
  }

  static DateTime _parseCsvDate(String str) {
    try {
      final parts = str.split(RegExp(r'[\/\-]'));
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          // yyyy-MM-dd
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          // dd/MM/yyyy
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return DateTime.now();
  }
}
