enum TransactionType {
  expense,
  income,
  transfer;

  String get label {
    switch (this) {
      case TransactionType.expense:
        return 'Despesa';
      case TransactionType.income:
        return 'Receita';
      case TransactionType.transfer:
        return 'Transferência';
    }
  }
}

enum AccountType {
  checking, // Conta Corrente
  cash, // Carteira / Dinheiro
  creditCard, // Cartão de Crédito
  savings, // Poupança
  investment; // Investimento

  String get label {
    switch (this) {
      case AccountType.checking:
        return 'Conta Corrente';
      case AccountType.cash:
        return 'Dinheiro / Carteira';
      case AccountType.creditCard:
        return 'Cartão de Crédito';
      case AccountType.savings:
        return 'Poupança';
      case AccountType.investment:
        return 'Investimentos';
    }
  }
}

enum InvoiceStatus {
  open, // Fatura Aberta
  closed, // Fatura Fechada
  paid; // Fatura Paga

  String get label {
    switch (this) {
      case InvoiceStatus.open:
        return 'Aberta';
      case InvoiceStatus.closed:
        return 'Fechada';
      case InvoiceStatus.paid:
        return 'Paga';
    }
  }
}

class UserProfile {
  final String id;
  final String name;
  final String currencySymbol;
  final DateTime createdAt;
  final bool hasPin;
  final bool useBiometrics;

  const UserProfile({
    required this.id,
    required this.name,
    this.currencySymbol = 'R\$',
    required this.createdAt,
    this.hasPin = false,
    this.useBiometrics = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currency_symbol': currencySymbol,
      'created_at': createdAt.toIso8601String(),
      'has_pin': hasPin ? 1 : 0,
      'use_biometrics': useBiometrics ? 1 : 0,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      currencySymbol: (map['currency_symbol'] as String?) ?? 'R\$',
      createdAt: DateTime.parse(map['created_at'] as String),
      hasPin: (map['has_pin'] as int? ?? 0) == 1,
      useBiometrics: (map['use_biometrics'] as int? ?? 1) == 1,
    );
  }

  UserProfile copyWith({
    String? name,
    String? currencySymbol,
    bool? hasPin,
    bool? useBiometrics,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      createdAt: createdAt,
      hasPin: hasPin ?? this.hasPin,
      useBiometrics: useBiometrics ?? this.useBiometrics,
    );
  }
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final double currentBalance;
  final double? creditLimit;
  final int? closingDay;
  final int? dueDay;
  final int colorValue;
  final String iconName;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    this.creditLimit,
    this.closingDay,
    this.dueDay,
    this.colorValue = 0xFF10B981,
    this.iconName = 'account_balance_wallet',
  });

  bool get isCreditCard => type == AccountType.creditCard;

  double get availableLimit {
    if (!isCreditCard || creditLimit == null) return 0.0;
    final used = currentBalance.abs();
    return (creditLimit! - used).clamp(0.0, creditLimit!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'credit_limit': creditLimit,
      'closing_day': closingDay,
      'due_day': dueDay,
      'color_value': colorValue,
      'icon_name': iconName,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.byName(map['type'] as String? ?? 'checking'),
      initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble(),
      closingDay: map['closing_day'] as int?,
      dueDay: map['due_day'] as int?,
      colorValue: map['color_value'] as int? ?? 0xFF10B981,
      iconName: map['icon_name'] as String? ?? 'account_balance_wallet',
    );
  }

  Account copyWith({
    String? name,
    AccountType? type,
    double? initialBalance,
    double? currentBalance,
    double? creditLimit,
    int? closingDay,
    int? dueDay,
    int? colorValue,
    String? iconName,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
    );
  }
}

class Category {
  final String id;
  final String name;
  final TransactionType type;
  final int colorValue;
  final String iconName;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    required this.iconName,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'color_value': colorValue,
      'icon_name': iconName,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TransactionType.values.byName(map['type'] as String? ?? 'expense'),
      colorValue: map['color_value'] as int? ?? 0xFF6366F1,
      iconName: map['icon_name'] as String? ?? 'category',
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}

class TransactionItem {
  final String id;
  final String accountId;
  final String? destinationAccountId;
  final String categoryId;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final bool isPaid;
  final int installmentIndex;
  final int totalInstallments;
  final String? installmentGroupId;
  final bool isRecurring;
  final String? notes;

  const TransactionItem({
    required this.id,
    required this.accountId,
    this.destinationAccountId,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.isPaid = true,
    this.installmentIndex = 1,
    this.totalInstallments = 1,
    this.installmentGroupId,
    this.isRecurring = false,
    this.notes,
  });

  bool get isInstallment => totalInstallments > 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'destination_account_id': destinationAccountId,
      'category_id': categoryId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'is_paid': isPaid ? 1 : 0,
      'installment_index': installmentIndex,
      'total_installments': totalInstallments,
      'installment_group_id': installmentGroupId,
      'is_recurring': isRecurring ? 1 : 0,
      'notes': notes,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      destinationAccountId: map['destination_account_id'] as String?,
      categoryId: map['category_id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values.byName(map['type'] as String? ?? 'expense'),
      isPaid: (map['is_paid'] as int? ?? 1) == 1,
      installmentIndex: map['installment_index'] as int? ?? 1,
      totalInstallments: map['total_installments'] as int? ?? 1,
      installmentGroupId: map['installment_group_id'] as String?,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
    );
  }

  TransactionItem copyWith({
    String? accountId,
    String? destinationAccountId,
    String? categoryId,
    String? description,
    double? amount,
    DateTime? date,
    TransactionType? type,
    bool? isPaid,
    int? installmentIndex,
    int? totalInstallments,
    String? installmentGroupId,
    bool? isRecurring,
    String? notes,
  }) {
    return TransactionItem(
      id: id,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      isPaid: isPaid ?? this.isPaid,
      installmentIndex: installmentIndex ?? this.installmentIndex,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      installmentGroupId: installmentGroupId ?? this.installmentGroupId,
      isRecurring: isRecurring ?? this.isRecurring,
      notes: notes ?? this.notes,
    );
  }
}

class Budget {
  final String id;
  final String categoryId;
  final double limitAmount;
  final String monthYear; // "yyyy-MM"

  const Budget({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.monthYear,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'limit_amount': limitAmount,
      'month_year': monthYear,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      limitAmount: (map['limit_amount'] as num).toDouble(),
      monthYear: map['month_year'] as String,
    );
  }
}

class RecurringRule {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final int dueDay;
  final bool isActive;
  final DateTime createdAt;
  final String? lastGeneratedMonth;

  const RecurringRule({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.dueDay,
    this.isActive = true,
    required this.createdAt,
    this.lastGeneratedMonth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category_id': categoryId,
      'account_id': accountId,
      'due_day': dueDay,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_generated_month': lastGeneratedMonth,
    };
  }

  factory RecurringRule.fromMap(Map<String, dynamic> map) {
    return RecurringRule(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.byName(map['type'] as String? ?? 'expense'),
      categoryId: map['category_id'] as String,
      accountId: map['account_id'] as String,
      dueDay: map['due_day'] as int? ?? 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastGeneratedMonth: map['last_generated_month'] as String?,
    );
  }

  RecurringRule copyWith({
    String? description,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    int? dueDay,
    bool? isActive,
    String? lastGeneratedMonth,
  }) {
    return RecurringRule(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastGeneratedMonth: lastGeneratedMonth ?? this.lastGeneratedMonth,
    );
  }
}

class CreditCardInvoice {
  final Account card;
  final String monthYearKey;
  final DateTime closingDate;
  final DateTime dueDate;
  final List<TransactionItem> items;
  final double totalAmount;
  final InvoiceStatus status;
  final int bestPurchaseDay;

  const CreditCardInvoice({
    required this.card,
    required this.monthYearKey,
    required this.closingDate,
    required this.dueDate,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.bestPurchaseDay,
  });
}

// --- Analytics Models (Fase 3) ---

class MonthlySummary {
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double cumulativeNetWorth;
  final Map<String, double> categoryExpenses;

  const MonthlySummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    this.cumulativeNetWorth = 0.0,
    required this.categoryExpenses,
  });

  double get savingsRate {
    if (totalIncome <= 0) return 0.0;
    return (netSavings / totalIncome) * 100;
  }
}

class CategoryComparison {
  final Category category;
  final double baseAmount;
  final double compareAmount;
  final double diffAmount; // compareAmount - baseAmount
  final double diffPercent; // ((compareAmount - baseAmount) / baseAmount) * 100

  const CategoryComparison({
    required this.category,
    required this.baseAmount,
    required this.compareAmount,
    required this.diffAmount,
    required this.diffPercent,
  });
}

class MonthComparison {
  final MonthlySummary base;
  final MonthlySummary compare;
  final double incomeDiff;
  final double incomeDiffPercent;
  final double expenseDiff;
  final double expenseDiffPercent;
  final double savingsDiff;
  final List<CategoryComparison> categoryComparisons;

  const MonthComparison({
    required this.base,
    required this.compare,
    required this.incomeDiff,
    required this.incomeDiffPercent,
    required this.expenseDiff,
    required this.expenseDiffPercent,
    required this.savingsDiff,
    required this.categoryComparisons,
  });
}
