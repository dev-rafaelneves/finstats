import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/import_candidate.dart';
import '../models/models.dart';
import '../utils/currency_formatter.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'security_service.dart';
import 'widget_service.dart';

class AppState extends ChangeNotifier {
  static const _uuid = Uuid();
  static const String _keyThemeMode = 'financeiro_theme_mode';
  static const String _keyOnboardingDone = 'financeiro_onboarding_done';
  static const String _keyDailyReminderEnabled = 'financeiro_daily_reminder_enabled';
  static const String _keyDailyReminderHour = 'financeiro_daily_reminder_hour';
  static const String _keyDailyReminderMinute = 'financeiro_daily_reminder_minute';
  static const String _keyBillReminderEnabled = 'financeiro_bill_reminder_enabled';

  SharedPreferences? _prefs;
  bool _initialized = false;

  UserProfile? _userProfile;
  bool _onboardingDone = false;
  ThemeMode _themeMode = ThemeMode.light;

  bool _hasPinLock = false;
  bool _isSessionUnlocked = true;

  bool _dailyReminderEnabled = false;
  int _dailyReminderHour = 20;
  int _dailyReminderMinute = 0;
  bool _billReminderEnabled = true;

  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<TransactionItem> _transactions = [];
  List<Budget> _budgets = [];
  List<RecurringRule> _recurringRules = [];

  DateTime _selectedMonth = DateTime.now();

  // Getters
  bool get initialized => _initialized;
  UserProfile? get userProfile => _userProfile;
  bool get onboardingDone => _onboardingDone;
  ThemeMode get themeMode => _themeMode;
  bool get hasPinLock => _hasPinLock;
  bool get isSessionUnlocked => _isSessionUnlocked;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get dailyReminderHour => _dailyReminderHour;
  int get dailyReminderMinute => _dailyReminderMinute;
  bool get billReminderEnabled => _billReminderEnabled;

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Account> get creditCards => _accounts.where((a) => a.isCreditCard).toList();
  List<Account> get bankAccounts => _accounts.where((a) => !a.isCreditCard).toList();

  List<Category> get categories => List.unmodifiable(_categories);
  List<TransactionItem> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<RecurringRule> get recurringRules => List.unmodifiable(_recurringRules);
  DateTime get selectedMonth => _selectedMonth;

  Map<String, Category> get categoryMap => {for (var c in _categories) c.id: c};
  Map<String, Account> get accountMap => {for (var a in _accounts) a.id: a};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await DatabaseService.init();

    final themeStr = _prefs?.getString(_keyThemeMode);
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _onboardingDone = _prefs?.getBool(_keyOnboardingDone) ?? false;

    _hasPinLock = await SecurityService.hasPin();
    if (_hasPinLock) {
      _isSessionUnlocked = false;
    }

    _dailyReminderEnabled = _prefs?.getBool(_keyDailyReminderEnabled) ?? false;
    _dailyReminderHour = _prefs?.getInt(_keyDailyReminderHour) ?? 20;
    _dailyReminderMinute = _prefs?.getInt(_keyDailyReminderMinute) ?? 0;
    _billReminderEnabled = _prefs?.getBool(_keyBillReminderEnabled) ?? true;

    await NotificationService.instance.init();
    await WidgetService.instance.init();

    await reloadData();
    await processRecurringTransactions(_selectedMonth);
    await syncHomeWidget();

    _initialized = true;
    notifyListeners();
  }

  Future<void> reloadData() async {
    _userProfile = await DatabaseService.getUserProfile();
    _accounts = await DatabaseService.getAccounts();
    _categories = await DatabaseService.getCategories();
    _transactions = await DatabaseService.getTransactions();
    _recurringRules = await DatabaseService.getRecurringRules();
    final monthKey = CurrencyFormatter.formatMonthYearKey(_selectedMonth);
    _budgets = await DatabaseService.getBudgets(monthKey);
    await syncHomeWidget();
    notifyListeners();
  }

  Future<void> syncHomeWidget() async {
    await WidgetService.instance.updateWidgetData(
      totalBalance: totalBalance,
      monthlyExpense: getMonthExpense(_selectedMonth),
      userName: _userProfile?.name,
    );
  }

  Future<void> setDailyReminder({required bool enabled, int? hour, int? minute}) async {
    _dailyReminderEnabled = enabled;
    if (hour != null) _dailyReminderHour = hour;
    if (minute != null) _dailyReminderMinute = minute;

    await _prefs?.setBool(_keyDailyReminderEnabled, enabled);
    await _prefs?.setInt(_keyDailyReminderHour, _dailyReminderHour);
    await _prefs?.setInt(_keyDailyReminderMinute, _dailyReminderMinute);

    if (enabled) {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleDailyExpenseReminder(
        hour: _dailyReminderHour,
        minute: _dailyReminderMinute,
      );
    } else {
      await NotificationService.instance.cancelDailyExpenseReminder();
    }
    notifyListeners();
  }

  Future<void> setBillReminder(bool enabled) async {
    _billReminderEnabled = enabled;
    await _prefs?.setBool(_keyBillReminderEnabled, enabled);
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month, 1);
    final monthKey = CurrencyFormatter.formatMonthYearKey(_selectedMonth);
    _budgets = await DatabaseService.getBudgets(monthKey);
    await processRecurringTransactions(_selectedMonth);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    if (mode == ThemeMode.dark) {
      await _prefs?.setString(_keyThemeMode, 'dark');
    } else if (mode == ThemeMode.light) {
      await _prefs?.setString(_keyThemeMode, 'light');
    } else {
      await _prefs?.setString(_keyThemeMode, 'system');
    }
    notifyListeners();
  }

  // --- Security ---
  Future<bool> unlockWithPin(String pin) async {
    final success = await SecurityService.verifyPin(pin);
    if (success) {
      _isSessionUnlocked = true;
      notifyListeners();
    }
    return success;
  }

  Future<bool> unlockWithBiometrics() async {
    final success = await SecurityService.authenticateWithBiometrics();
    if (success) {
      _isSessionUnlocked = true;
      notifyListeners();
    }
    return success;
  }

  void lockSession() {
    if (_hasPinLock) {
      _isSessionUnlocked = false;
      notifyListeners();
    }
  }

  Future<bool> setupPin(String pin) async {
    final success = await SecurityService.setPin(pin);
    if (success) {
      _hasPinLock = true;
      _isSessionUnlocked = true;
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(hasPin: true);
        await DatabaseService.saveUserProfile(_userProfile!);
      }
      notifyListeners();
    }
    return success;
  }

  Future<void> removePin() async {
    await SecurityService.removePin();
    _hasPinLock = false;
    _isSessionUnlocked = true;
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(hasPin: false);
      await DatabaseService.saveUserProfile(_userProfile!);
    }
    notifyListeners();
  }

  Future<void> updateProfile({required String name}) async {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(name: name.trim());
      await DatabaseService.saveUserProfile(_userProfile!);
    } else {
      _userProfile = UserProfile(
        id: _uuid.v4(),
        name: name.trim().isEmpty ? 'Usuário' : name.trim(),
        createdAt: DateTime.now(),
      );
      await DatabaseService.saveUserProfile(_userProfile!);
    }
    await syncHomeWidget();
    notifyListeners();
  }

  // --- Onboarding ---
  Future<void> completeOnboarding({
    required String name,
    required double initialBalance,
  }) async {
    final profile = UserProfile(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Usuário' : name.trim(),
      createdAt: DateTime.now(),
    );
    await DatabaseService.saveUserProfile(profile);

    // Conta Corrente
    final mainAccount = Account(
      id: _uuid.v4(),
      name: 'Conta Corrente Principal',
      type: AccountType.checking,
      initialBalance: initialBalance,
      currentBalance: initialBalance,
      colorValue: 0xFF10B981,
      iconName: 'account_balance',
    );
    await DatabaseService.insertAccount(mainAccount);

    // Carteira / Dinheiro
    final cashAccount = Account(
      id: _uuid.v4(),
      name: 'Carteira / Dinheiro',
      type: AccountType.cash,
      initialBalance: 0.0,
      currentBalance: 0.0,
      colorValue: 0xFF059669,
      iconName: 'account_balance_wallet',
    );
    await DatabaseService.insertAccount(cashAccount);

    // Cartão de Crédito Padrão
    final defaultCard = Account(
      id: _uuid.v4(),
      name: 'Cartão de Crédito',
      type: AccountType.creditCard,
      initialBalance: 0.0,
      currentBalance: 0.0,
      creditLimit: 3000.0,
      closingDay: 20,
      dueDay: 28,
      colorValue: 0xFF8B5CF6,
      iconName: 'credit_card',
    );
    await DatabaseService.insertAccount(defaultCard);

    _onboardingDone = true;
    await _prefs?.setBool(_keyOnboardingDone, true);
    await reloadData();
  }

  // --- Accounts ---
  Future<void> addAccount(Account account) async {
    await DatabaseService.insertAccount(account);
    await reloadData();
  }

  Future<void> updateAccount(Account account) async {
    await DatabaseService.updateAccount(account);
    await _recalculateAccountBalances();
    await reloadData();
  }

  Future<void> deleteAccount(String accountId) async {
    await DatabaseService.deleteAccount(accountId);
    await reloadData();
  }

  // --- Transactions ---
  Future<void> addTransaction({
    required String accountId,
    String? destinationAccountId,
    required String categoryId,
    required String description,
    required double amount,
    required DateTime date,
    required TransactionType type,
    bool isPaid = true,
    int totalInstallments = 1,
    bool isRecurring = false,
    String? notes,
  }) async {
    if (totalInstallments > 1 && type == TransactionType.expense) {
      final installmentGroupId = _uuid.v4();
      final installmentValue = (amount / totalInstallments);

      for (int i = 1; i <= totalInstallments; i++) {
        final installmentDate = DateTime(date.year, date.month + (i - 1), date.day);
        final tx = TransactionItem(
          id: _uuid.v4(),
          accountId: accountId,
          categoryId: categoryId,
          description: description,
          amount: installmentValue,
          date: installmentDate,
          type: type,
          isPaid: i == 1 ? isPaid : false,
          installmentIndex: i,
          totalInstallments: totalInstallments,
          installmentGroupId: installmentGroupId,
          isRecurring: false,
          notes: notes,
        );
        await DatabaseService.insertTransaction(tx);
      }
    } else {
      final tx = TransactionItem(
        id: _uuid.v4(),
        accountId: accountId,
        destinationAccountId: destinationAccountId,
        categoryId: categoryId,
        description: description,
        amount: amount,
        date: date,
        type: type,
        isPaid: isPaid,
        installmentIndex: 1,
        totalInstallments: 1,
        isRecurring: isRecurring,
        notes: notes,
      );
      await DatabaseService.insertTransaction(tx);
    }

    await _recalculateAccountBalances();
    await reloadData();
  }

  Future<void> updateTransaction(TransactionItem tx) async {
    await DatabaseService.updateTransaction(tx);
    await _recalculateAccountBalances();
    await reloadData();
  }

  Future<void> toggleTransactionPaid(String id) async {
    final tx = _transactions.firstWhere((t) => t.id == id);
    final updated = tx.copyWith(isPaid: !tx.isPaid);
    await DatabaseService.updateTransaction(updated);
    await _recalculateAccountBalances();
    await reloadData();
  }

  Future<void> deleteTransaction(String id) async {
    await DatabaseService.deleteTransaction(id);
    await _recalculateAccountBalances();
    await reloadData();
  }

  Future<void> deleteInstallmentGroup(String groupId) async {
    await DatabaseService.deleteTransactionsByGroupId(groupId);
    await _recalculateAccountBalances();
    await reloadData();
  }

  Future<void> _recalculateAccountBalances() async {
    final allTxs = await DatabaseService.getTransactions();
    final allAccs = await DatabaseService.getAccounts();

    for (final acc in allAccs) {
      double running = acc.initialBalance;

      for (final tx in allTxs) {
        if (!tx.isPaid) continue;

        if (acc.isCreditCard) {
          // Em cartão de crédito, despesas aumentam o valor da fatura a pagar (saldo negativo/usado)
          if (tx.accountId == acc.id && tx.type == TransactionType.expense) {
            running += tx.amount;
          } else if (tx.destinationAccountId == acc.id && tx.type == TransactionType.transfer) {
            // Pagamento de fatura reduz o valor devido
            running -= tx.amount;
          }
        } else {
          // Em contas bancárias normais
          if (tx.type == TransactionType.expense && tx.accountId == acc.id) {
            running -= tx.amount;
          } else if (tx.type == TransactionType.income && tx.accountId == acc.id) {
            running += tx.amount;
          } else if (tx.type == TransactionType.transfer) {
            if (tx.accountId == acc.id) {
              running -= tx.amount;
            } else if (tx.destinationAccountId == acc.id) {
              running += tx.amount;
            }
          }
        }
      }

      await DatabaseService.updateAccount(acc.copyWith(currentBalance: running));
    }
  }

  Future<int> importTransactionsInBatch({
    required List<ImportCandidate> candidates,
    required String accountId,
  }) async {
    final toImport = candidates.where((c) => c.isSelected).toList();
    if (toImport.isEmpty) return 0;

    for (final candidate in toImport) {
      final tx = candidate.toTransactionItem(accountId: accountId);
      await DatabaseService.insertTransaction(tx);
    }

    await _recalculateAccountBalances();
    await reloadData();
    return toImport.length;
  }

  // --- Budgets ---
  Future<void> setBudget({
    required String categoryId,
    required double limitAmount,
    required String monthYear,
  }) async {
    final budget = Budget(
      id: _uuid.v4(),
      categoryId: categoryId,
      limitAmount: limitAmount,
      monthYear: monthYear,
    );
    await DatabaseService.saveBudget(budget);
    await reloadData();
  }

  // --- Recurring Rules (Motor de Recorrência) ---
  Future<void> addRecurringRule(RecurringRule rule) async {
    await DatabaseService.insertRecurringRule(rule);
    await reloadData();
    await processRecurringTransactions(_selectedMonth);
  }

  Future<void> updateRecurringRule(RecurringRule rule) async {
    await DatabaseService.updateRecurringRule(rule);
    await reloadData();
  }

  Future<void> toggleRecurringRule(String id) async {
    final rule = _recurringRules.firstWhere((r) => r.id == id);
    final updated = rule.copyWith(isActive: !rule.isActive);
    await DatabaseService.updateRecurringRule(updated);
    await reloadData();
  }

  Future<void> deleteRecurringRule(String id) async {
    await DatabaseService.deleteRecurringRule(id);
    await reloadData();
  }

  Future<void> processRecurringTransactions(DateTime targetMonth) async {
    final monthKey = CurrencyFormatter.formatMonthYearKey(targetMonth);
    final rules = await DatabaseService.getRecurringRules();
    final allTxs = await DatabaseService.getTransactions();

    for (final rule in rules) {
      if (!rule.isActive) continue;

      // Verifica se já existe transação gerada para esta regra neste mês
      final alreadyExists = allTxs.any((t) =>
          t.isRecurring &&
          t.description == rule.description &&
          t.amount == rule.amount &&
          t.date.year == targetMonth.year &&
          t.date.month == targetMonth.month);

      if (!alreadyExists) {
        final daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
        final actualDay = rule.dueDay.clamp(1, daysInMonth);
        final txDate = DateTime(targetMonth.year, targetMonth.month, actualDay);

        final newTx = TransactionItem(
          id: _uuid.v4(),
          accountId: rule.accountId,
          categoryId: rule.categoryId,
          description: rule.description,
          amount: rule.amount,
          date: txDate,
          type: rule.type,
          isPaid: false, // Inicia pendente até o usuário marcar ou pagar
          isRecurring: true,
          notes: 'Gerado automaticamente por regra recorrente',
        );

        await DatabaseService.insertTransaction(newTx);
        await DatabaseService.updateRecurringRule(rule.copyWith(lastGeneratedMonth: monthKey));
      }
    }

    await reloadData();
  }

  // --- Credit Card Invoices (Ciclo de Faturas & Pagamento) ---
  CreditCardInvoice getCardInvoice(Account card, DateTime month) {
    final closingDay = card.closingDay ?? 20;
    final dueDay = card.dueDay ?? 28;

    final invoiceMonthKey = CurrencyFormatter.formatMonthYearKey(month);

    // Período da fatura: do dia de fechamento do mês anterior até o fechamento deste mês
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final prevClosingDate = DateTime(prevMonth.year, prevMonth.month, closingDay);
    final currentClosingDate = DateTime(month.year, month.month, closingDay);
    final currentDueDate = DateTime(month.year, month.month, dueDay);

    // Itens pertencentes a este ciclo do cartão
    final invoiceItems = _transactions.where((t) {
      if (t.accountId != card.id || t.type != TransactionType.expense) return false;
      return t.date.isAfter(prevClosingDate) && !t.date.isAfter(currentClosingDate);
    }).toList();

    final total = invoiceItems.fold(0.0, (sum, t) => sum + t.amount);

    // Verifica se houve pagamento registrado para este cartão neste mês
    final hasPayment = _transactions.any((t) =>
        t.type == TransactionType.transfer &&
        t.destinationAccountId == card.id &&
        t.date.year == month.year &&
        t.date.month == month.month &&
        t.isPaid);

    InvoiceStatus status;
    if (hasPayment || (invoiceItems.isNotEmpty && invoiceItems.every((i) => i.isPaid))) {
      status = InvoiceStatus.paid;
    } else if (DateTime.now().isAfter(currentClosingDate)) {
      status = InvoiceStatus.closed;
    } else {
      status = InvoiceStatus.open;
    }

    return CreditCardInvoice(
      card: card,
      monthYearKey: invoiceMonthKey,
      closingDate: currentClosingDate,
      dueDate: currentDueDate,
      items: invoiceItems,
      totalAmount: total,
      status: status,
      bestPurchaseDay: closingDay, // O melhor dia para compra é o dia do fechamento
    );
  }

  Future<void> payCreditCardInvoice({
    required String cardId,
    required String debitAccountId,
    required double amount,
    required DateTime paymentDate,
  }) async {
    final card = _accounts.firstWhere((a) => a.id == cardId);

    // Registra a transferência da conta corrente para o cartão de crédito
    final paymentTx = TransactionItem(
      id: _uuid.v4(),
      accountId: debitAccountId,
      destinationAccountId: cardId,
      categoryId: 'cat_transfer',
      description: 'Pagamento Fatura ${card.name}',
      amount: amount,
      date: paymentDate,
      type: TransactionType.transfer,
      isPaid: true,
      notes: 'Liquidação de fatura do cartão de crédito',
    );

    await DatabaseService.insertTransaction(paymentTx);

    // Marca as despesas do ciclo como pagas
    final invoice = getCardInvoice(card, paymentDate);
    for (final item in invoice.items) {
      if (!item.isPaid) {
        await DatabaseService.updateTransaction(item.copyWith(isPaid: true));
      }
    }

    await _recalculateAccountBalances();
    await reloadData();
  }

  // --- Calculations for UI ---
  double get totalBalance {
    return _accounts.fold(0.0, (sum, acc) {
      if (acc.isCreditCard) {
        return sum - acc.currentBalance.abs();
      }
      return sum + acc.currentBalance;
    });
  }

  List<TransactionItem> getMonthTransactions(DateTime month) {
    return _transactions.where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList();
  }

  double getMonthIncome(DateTime month) {
    return getMonthTransactions(month)
        .where((t) => t.type == TransactionType.income && t.isPaid)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthExpense(DateTime month) {
    return getMonthTransactions(month)
        .where((t) => t.type == TransactionType.expense && t.isPaid)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthSavings(DateTime month) {
    return getMonthIncome(month) - getMonthExpense(month);
  }

  Map<String, double> getCategoryExpenses(DateTime month) {
    final map = <String, double>{};
    for (final tx in getMonthTransactions(month)) {
      if (tx.type == TransactionType.expense && tx.isPaid) {
        map[tx.categoryId] = (map[tx.categoryId] ?? 0.0) + tx.amount;
      }
    }
    return map;
  }

  // --- Analytics & Insights (Fase 3) ---

  MonthlySummary getMonthlySummary(DateTime month) {
    final income = getMonthIncome(month);
    final expense = getMonthExpense(month);
    final savings = income - expense;
    final catExpenses = getCategoryExpenses(month);

    return MonthlySummary(
      month: DateTime(month.year, month.month, 1),
      totalIncome: income,
      totalExpense: expense,
      netSavings: savings,
      categoryExpenses: catExpenses,
    );
  }

  List<MonthlySummary> getHistoricalMonths({int count = 6}) {
    final list = <MonthlySummary>[];
    final current = DateTime(_selectedMonth.year, _selectedMonth.month, 1);

    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(current.year, current.month - i, 1);
      final summary = getMonthlySummary(m);
      list.add(summary);
    }
    return list;
  }

  MonthComparison compareMonths(DateTime baseMonth, DateTime compareMonth) {
    final baseSummary = getMonthlySummary(baseMonth);
    final compareSummary = getMonthlySummary(compareMonth);

    final incomeDiff = compareSummary.totalIncome - baseSummary.totalIncome;
    final incomeDiffPercent = baseSummary.totalIncome > 0
        ? (incomeDiff / baseSummary.totalIncome) * 100
        : (compareSummary.totalIncome > 0 ? 100.0 : 0.0);

    final expenseDiff = compareSummary.totalExpense - baseSummary.totalExpense;
    final expenseDiffPercent = baseSummary.totalExpense > 0
        ? (expenseDiff / baseSummary.totalExpense) * 100
        : (compareSummary.totalExpense > 0 ? 100.0 : 0.0);

    final savingsDiff = compareSummary.netSavings - baseSummary.netSavings;

    // Comparação categoria a categoria
    final allCategoryIds = {
      ...baseSummary.categoryExpenses.keys,
      ...compareSummary.categoryExpenses.keys,
    };

    final categoryComparisons = <CategoryComparison>[];

    for (final catId in allCategoryIds) {
      final cat = categoryMap[catId];
      if (cat == null) continue;

      final bAmount = baseSummary.categoryExpenses[catId] ?? 0.0;
      final cAmount = compareSummary.categoryExpenses[catId] ?? 0.0;
      final diff = cAmount - bAmount;
      final diffPct = bAmount > 0
          ? (diff / bAmount) * 100
          : (cAmount > 0 ? 100.0 : 0.0);

      categoryComparisons.add(
        CategoryComparison(
          category: cat,
          baseAmount: bAmount,
          compareAmount: cAmount,
          diffAmount: diff,
          diffPercent: diffPct,
        ),
      );
    }

    // Ordena da categoria com maior variação para a menor
    categoryComparisons.sort((a, b) => b.diffAmount.abs().compareTo(a.diffAmount.abs()));

    return MonthComparison(
      base: baseSummary,
      compare: compareSummary,
      incomeDiff: incomeDiff,
      incomeDiffPercent: incomeDiffPercent,
      expenseDiff: expenseDiff,
      expenseDiffPercent: expenseDiffPercent,
      savingsDiff: savingsDiff,
      categoryComparisons: categoryComparisons,
    );
  }

  double getSavingsRate(DateTime month) {
    final income = getMonthIncome(month);
    if (income <= 0) return 0.0;
    final savings = getMonthSavings(month);
    return (savings / income) * 100;
  }

  List<Map<String, dynamic>> getBudgetAlerts(DateTime month) {
    final alerts = <Map<String, dynamic>>[];
    final catExpenses = getCategoryExpenses(month);

    for (final budget in _budgets) {
      final spent = catExpenses[budget.categoryId] ?? 0.0;
      final cat = categoryMap[budget.categoryId];
      if (cat == null || budget.limitAmount <= 0) continue;

      final pct = (spent / budget.limitAmount) * 100;
      if (pct >= 85.0) {
        alerts.add({
          'category': cat,
          'spent': spent,
          'limit': budget.limitAmount,
          'percent': pct,
          'isExceeded': pct >= 100.0,
        });
      }
    }
    return alerts;
  }
}
