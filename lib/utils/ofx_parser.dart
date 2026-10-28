import 'package:uuid/uuid.dart';
import '../models/import_candidate.dart';
import '../models/models.dart';

class OfxParser {
  static const _uuid = Uuid();

  static List<ImportCandidate> parse(
    String content, {
    required List<Category> availableCategories,
    required List<TransactionItem> existingTransactions,
  }) {
    final candidates = <ImportCandidate>[];

    // Separa os blocos <STMTTRN>
    final regexTrn = RegExp(
      r'<STMTTRN>([\s\S]*?)(?:<\/STMTTRN>|(?=<STMTTRN>)|(?=<\/BANKTRANLIST>)|$)',
      caseSensitive: false,
    );

    final matches = regexTrn.allMatches(content);

    final defaultExpenseCat = availableCategories.firstWhere(
      (c) => c.type == TransactionType.expense,
      orElse: () => availableCategories.first,
    );

    final defaultIncomeCat = availableCategories.firstWhere(
      (c) => c.type == TransactionType.income,
      orElse: () => availableCategories.first,
    );

    for (final m in matches) {
      final block = m.group(1) ?? '';
      if (block.trim().isEmpty) continue;

      final typeStr = _extractTagValue(block, 'TRNTYPE');
      final dtPostedStr = _extractTagValue(block, 'DTPOSTED');
      final amtStr = _extractTagValue(block, 'TRNAMT');
      final memo = _extractTagValue(block, 'MEMO');
      final name = _extractTagValue(block, 'NAME');
      final fitId = _extractTagValue(block, 'FITID');

      if (amtStr.isEmpty) continue;

      final rawAmount = double.tryParse(amtStr.replaceAll(',', '.')) ?? 0.0;
      final isNegative = rawAmount < 0;
      final absAmount = rawAmount.abs();

      final description = (memo.isNotEmpty ? memo : (name.isNotEmpty ? name : 'Lançamento')).trim();
      final date = _parseOfxDate(dtPostedStr);

      final TransactionType txType;
      if (typeStr.toUpperCase() == 'CREDIT' || (!isNegative && rawAmount > 0)) {
        txType = TransactionType.income;
      } else {
        txType = TransactionType.expense;
      }

      // Sugestão de categoria por palavras-chave
      final suggestedCat = guessCategory(
        description,
        txType,
        availableCategories,
        txType == TransactionType.income ? defaultIncomeCat : defaultExpenseCat,
      );

      // Verificação de duplicação inteligente
      final isDuplicate = existingTransactions.any((t) {
        final sameAmount = (t.amount - absAmount).abs() < 0.01;
        final sameDay = t.date.year == date.year && t.date.month == date.month && t.date.day == date.day;
        final sameDesc = t.description.toLowerCase().contains(description.toLowerCase()) ||
            description.toLowerCase().contains(t.description.toLowerCase());
        return sameAmount && sameDay && sameDesc;
      });

      candidates.add(
        ImportCandidate(
          id: _uuid.v4(),
          description: description,
          amount: absAmount,
          date: date,
          type: txType,
          fitId: fitId.isNotEmpty ? fitId : null,
          isDuplicate: isDuplicate,
          isSelected: !isDuplicate, // Desmarca automaticamente por segurança se já for duplicado
          categoryId: suggestedCat.id,
        ),
      );
    }

    return candidates;
  }

  static String _extractTagValue(String block, String tag) {
    final reg = RegExp('<$tag>([^<\r\n]+)', caseSensitive: false);
    final match = reg.firstMatch(block);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    return '';
  }

  static DateTime _parseOfxDate(String dtStr) {
    if (dtStr.length >= 8) {
      final y = int.tryParse(dtStr.substring(0, 4)) ?? DateTime.now().year;
      final m = int.tryParse(dtStr.substring(4, 6)) ?? DateTime.now().month;
      final d = int.tryParse(dtStr.substring(6, 8)) ?? DateTime.now().day;
      return DateTime(y, m, d);
    }
    return DateTime.now();
  }

  static Category guessCategory(
    String desc,
    TransactionType type,
    List<Category> categories,
    Category fallback,
  ) {
    final lower = desc.toLowerCase();

    for (final cat in categories) {
      if (cat.type != type) continue;
      final catName = cat.name.toLowerCase();

      if (lower.contains('supermercado') || lower.contains('mercado') || lower.contains('padaria') || lower.contains('restaurante') || lower.contains('ifood')) {
        if (catName.contains('alimenta') || catName.contains('comida')) return cat;
      }
      if (lower.contains('uber') || lower.contains('posto') || lower.contains('combustivel') || lower.contains('gasolina') || lower.contains('estacionamento')) {
        if (catName.contains('transporte')) return cat;
      }
      if (lower.contains('farmacia') || lower.contains('drogaria') || lower.contains('medico') || lower.contains('hospital')) {
        if (catName.contains('saúde') || catName.contains('farm')) return cat;
      }
      if (lower.contains('aluguel') || lower.contains('condominio') || lower.contains('luz') || lower.contains('energia') || lower.contains('enel') || lower.contains('sabesp') || lower.contains('agua') || lower.contains('internet')) {
        if (catName.contains('moradia') || catName.contains('contas')) return cat;
      }
      if (lower.contains('salario') || lower.contains('folha') || lower.contains('pagamento recebido') || lower.contains('remunera')) {
        if (catName.contains('salário') || catName.contains('remunera')) return cat;
      }
    }

    return fallback;
  }
}
