import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _database;
  static const _uuid = Uuid();

  static bool get isAvailable => _database != null && _database!.isOpen;
  static Database? get db => _database;

  static Future<void> init({Database? customDb}) async {
    if (customDb != null) {
      _database = customDb;
      return;
    }

    if (_database != null && _database!.isOpen) return;

    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'financeiro.db');

      _database = await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      // Garante criação da tabela caso banco já existisse
      await _database?.execute('''
        CREATE TABLE IF NOT EXISTS recurring_rules (
          id TEXT PRIMARY KEY,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category_id TEXT NOT NULL,
          account_id TEXT NOT NULL,
          due_day INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          last_generated_month TEXT
        )
      ''');
    } catch (_) {
      _database = null;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        created_at TEXT NOT NULL,
        has_pin INTEGER NOT NULL DEFAULT 0,
        use_biometrics INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0.0,
        current_balance REAL NOT NULL DEFAULT 0.0,
        credit_limit REAL,
        closing_day INTEGER,
        due_day INTEGER,
        color_value INTEGER NOT NULL,
        icon_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_name TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        destination_account_id TEXT,
        category_id TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 1,
        installment_index INTEGER NOT NULL DEFAULT 1,
        total_installments INTEGER NOT NULL DEFAULT 1,
        installment_group_id TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        month_year TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_rules (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        due_day INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        last_generated_month TEXT
      )
    ''');

    await _seedDefaults(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_rules (
          id TEXT PRIMARY KEY,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category_id TEXT NOT NULL,
          account_id TEXT NOT NULL,
          due_day INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          last_generated_month TEXT
        )
      ''');
    }
  }

  static Future<void> _seedDefaults(Database db) async {
    final defaultExpenses = [
      {'name': 'Alimentação', 'color': 0xFFF97316, 'icon': 'restaurant'},
      {'name': 'Moradia & Contas', 'color': 0xFF3B82F6, 'icon': 'home'},
      {'name': 'Transporte', 'color': 0xFFEAB308, 'icon': 'directions_car'},
      {'name': 'Saúde & Farmácia', 'color': 0xFFEF4444, 'icon': 'local_hospital'},
      {'name': 'Lazer & Entretenimento', 'color': 0xFF8B5CF6, 'icon': 'sports_esports'},
      {'name': 'Educação', 'color': 0xFF06B6D4, 'icon': 'school'},
      {'name': 'Compras Pessoais', 'color': 0xFFEC4899, 'icon': 'shopping_cart'},
      {'name': 'Pagamento de Fatura', 'color': 0xFF6366F1, 'icon': 'credit_card'},
      {'name': 'Outras Despesas', 'color': 0xFF64748B, 'icon': 'category'},
    ];

    for (final cat in defaultExpenses) {
      await db.insert('categories', {
        'id': _uuid.v4(),
        'name': cat['name'],
        'type': 'expense',
        'color_value': cat['color'],
        'icon_name': cat['icon'],
        'is_default': 1,
      });
    }

    final defaultIncomes = [
      {'name': 'Salário & Remuneração', 'color': 0xFF10B981, 'icon': 'work'},
      {'name': 'Rendimentos & Investimentos', 'color': 0xFF059669, 'icon': 'trending_up'},
      {'name': 'Freelas & Serviços', 'color': 0xFF34D399, 'icon': 'attach_money'},
      {'name': 'Presentes & Outros', 'color': 0xFF14B8A6, 'icon': 'savings'},
    ];

    for (final cat in defaultIncomes) {
      await db.insert('categories', {
        'id': _uuid.v4(),
        'name': cat['name'],
        'type': 'income',
        'color_value': cat['color'],
        'icon_name': cat['icon'],
        'is_default': 1,
      });
    }

    await db.insert('categories', {
      'id': 'cat_transfer',
      'name': 'Transferência entre Contas',
      'type': 'transfer',
      'color_value': 0xFF6366F1,
      'icon_name': 'swap_horiz',
      'is_default': 1,
    });
  }

  // --- Profile ---
  static Future<UserProfile?> getUserProfile() async {
    if (!isAvailable) return null;
    final res = await _database!.query('user_profile', limit: 1);
    if (res.isEmpty) return null;
    return UserProfile.fromMap(res.first);
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    if (!isAvailable) return;
    await _database!.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Accounts ---
  static Future<List<Account>> getAccounts() async {
    if (!isAvailable) return [];
    final res = await _database!.query('accounts', orderBy: 'name ASC');
    return res.map((m) => Account.fromMap(m)).toList();
  }

  static Future<void> insertAccount(Account account) async {
    if (!isAvailable) return;
    await _database!.insert('accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateAccount(Account account) async {
    if (!isAvailable) return;
    await _database!.update('accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id]);
  }

  static Future<void> deleteAccount(String id) async {
    if (!isAvailable) return;
    await _database!.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Categories ---
  static Future<List<Category>> getCategories() async {
    if (!isAvailable) return [];
    final res = await _database!.query('categories', orderBy: 'name ASC');
    return res.map((m) => Category.fromMap(m)).toList();
  }

  static Future<void> insertCategory(Category category) async {
    if (!isAvailable) return;
    await _database!.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Transactions ---
  static Future<List<TransactionItem>> getTransactions() async {
    if (!isAvailable) return [];
    final res = await _database!.query('transactions', orderBy: 'date DESC');
    return res.map((m) => TransactionItem.fromMap(m)).toList();
  }

  static Future<void> insertTransaction(TransactionItem tx) async {
    if (!isAvailable) return;
    await _database!.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateTransaction(TransactionItem tx) async {
    if (!isAvailable) return;
    await _database!.update('transactions', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
  }

  static Future<void> deleteTransaction(String id) async {
    if (!isAvailable) return;
    await _database!.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteTransactionsByGroupId(String groupId) async {
    if (!isAvailable) return;
    await _database!.delete('transactions', where: 'installment_group_id = ?', whereArgs: [groupId]);
  }

  // --- Budgets ---
  static Future<List<Budget>> getBudgets(String monthYear) async {
    if (!isAvailable) return [];
    final res = await _database!.query('budgets', where: 'month_year = ?', whereArgs: [monthYear]);
    return res.map((m) => Budget.fromMap(m)).toList();
  }

  static Future<void> saveBudget(Budget budget) async {
    if (!isAvailable) return;
    await _database!.insert('budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteBudget(String id) async {
    if (!isAvailable) return;
    await _database!.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Recurring Rules ---
  static Future<List<RecurringRule>> getRecurringRules() async {
    if (!isAvailable) return [];
    final res = await _database!.query('recurring_rules', orderBy: 'due_day ASC');
    return res.map((m) => RecurringRule.fromMap(m)).toList();
  }

  static Future<void> insertRecurringRule(RecurringRule rule) async {
    if (!isAvailable) return;
    await _database!.insert('recurring_rules', rule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateRecurringRule(RecurringRule rule) async {
    if (!isAvailable) return;
    await _database!.update('recurring_rules', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
  }

  static Future<void> deleteRecurringRule(String id) async {
    if (!isAvailable) return;
    await _database!.delete('recurring_rules', where: 'id = ?', whereArgs: [id]);
  }

  // --- Backup / Export Raw Data ---
  static Future<Map<String, dynamic>> exportAllData() async {
    if (!isAvailable) return {};
    final profiles = await _database!.query('user_profile');
    final accounts = await _database!.query('accounts');
    final categories = await _database!.query('categories');
    final transactions = await _database!.query('transactions');
    final budgets = await _database!.query('budgets');
    final recurring = await _database!.query('recurring_rules');

    return {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'user_profile': profiles,
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'budgets': budgets,
      'recurring_rules': recurring,
    };
  }

  static Future<void> restoreAllData(Map<String, dynamic> data) async {
    if (!isAvailable) return;
    await _database!.transaction((txn) async {
      await txn.delete('user_profile');
      await txn.delete('accounts');
      await txn.delete('categories');
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('recurring_rules');

      if (data['user_profile'] is List) {
        for (final row in data['user_profile']) {
          await txn.insert('user_profile', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['accounts'] is List) {
        for (final row in data['accounts']) {
          await txn.insert('accounts', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['categories'] is List) {
        for (final row in data['categories']) {
          await txn.insert('categories', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['transactions'] is List) {
        for (final row in data['transactions']) {
          await txn.insert('transactions', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['budgets'] is List) {
        for (final row in data['budgets']) {
          await txn.insert('budgets', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['recurring_rules'] is List) {
        for (final row in data['recurring_rules']) {
          await txn.insert('recurring_rules', Map<String, dynamic>.from(row as Map));
        }
      }
    });
  }
}
