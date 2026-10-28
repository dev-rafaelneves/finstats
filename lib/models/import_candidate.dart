import 'models.dart';

class ImportCandidate {
  final String id;
  String description;
  double amount;
  DateTime date;
  TransactionType type;
  String? fitId;
  bool isSelected;
  bool isDuplicate;
  String categoryId;

  ImportCandidate({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.fitId,
    this.isSelected = true,
    this.isDuplicate = false,
    required this.categoryId,
  });

  TransactionItem toTransactionItem({
    required String accountId,
  }) {
    return TransactionItem(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      description: description,
      amount: amount,
      date: date,
      type: type,
      isPaid: true,
      notes: fitId != null ? 'Importado de extrato bancário (FITID: $fitId)' : 'Importado de extrato bancário',
    );
  }
}
