import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financeiro/models/models.dart';
import 'package:financeiro/utils/currency_formatter.dart';
import 'package:financeiro/utils/ofx_parser.dart';
import 'package:financeiro/utils/csv_bank_parser.dart';
import 'package:financeiro/utils/export_csv_generator.dart';
import 'package:financeiro/services/notification_service.dart';
import 'package:financeiro/services/widget_service.dart';
import 'package:financeiro/widgets/summary_card.dart';

void main() {
  group('Financeiro Unit & Model Tests', () {
    test('CurrencyFormatter formats BRL correctly', () {
      expect(CurrencyFormatter.format(1250.50), contains('1.250,50'));
      expect(CurrencyFormatter.format(0.0), contains('0,00'));
    });

    test('TransactionItem installment logic works', () {
      final tx = TransactionItem(
        id: '1',
        accountId: 'acc1',
        categoryId: 'cat1',
        description: 'Smartphone',
        amount: 300.0,
        date: DateTime.now(),
        type: TransactionType.expense,
        installmentIndex: 1,
        totalInstallments: 3,
        installmentGroupId: 'group-123',
      );

      expect(tx.isInstallment, isTrue);
      expect(tx.installmentIndex, equals(1));
      expect(tx.totalInstallments, equals(3));
      expect(tx.installmentGroupId, equals('group-123'));
    });

    test('Account credit card limit and available limit calculation', () {
      const card = Account(
        id: 'card1',
        name: 'Cartão Black',
        type: AccountType.creditCard,
        creditLimit: 5000.0,
        currentBalance: 1200.0,
        closingDay: 20,
        dueDay: 28,
      );

      expect(card.isCreditCard, isTrue);
      expect(card.creditLimit, equals(5000.0));
      expect(card.availableLimit, equals(3800.0));
    });

    test('CreditCardInvoice status and properties (Fase 2 & 6)', () {
      const card = Account(
        id: 'card1',
        name: 'Nubank Ultravioleta',
        type: AccountType.creditCard,
        creditLimit: 10000.0,
        closingDay: 15,
        dueDay: 22,
      );

      final invoice = CreditCardInvoice(
        card: card,
        monthYearKey: '2026-10',
        closingDate: DateTime(2026, 10, 15),
        dueDate: DateTime(2026, 10, 22),
        items: [],
        totalAmount: 1450.75,
        status: InvoiceStatus.open,
        bestPurchaseDay: 16,
      );

      expect(invoice.card.name, equals('Nubank Ultravioleta'));
      expect(invoice.totalAmount, equals(1450.75));
      expect(invoice.status, equals(InvoiceStatus.open));
      expect(invoice.status.label, equals('Aberta'));
      expect(invoice.bestPurchaseDay, equals(16));
    });

    test('RecurringRule model serialization & deserialization', () {
      final rule = RecurringRule(
        id: 'rule1',
        description: 'Internet Fibra',
        amount: 119.90,
        type: TransactionType.expense,
        categoryId: 'cat_moradia',
        accountId: 'acc_principal',
        dueDay: 15,
        isActive: true,
        createdAt: DateTime.parse('2026-10-01T10:00:00.000'),
      );

      final map = rule.toMap();
      final restored = RecurringRule.fromMap(map);

      expect(restored.id, equals('rule1'));
      expect(restored.description, equals('Internet Fibra'));
      expect(restored.amount, equals(119.90));
      expect(restored.dueDay, equals(15));
      expect(restored.isActive, isTrue);
    });

    test('MonthlySummary savingsRate calculation and zero income handling (Fase 3 & 6)', () {
      final summary = MonthlySummary(
        month: DateTime(2026, 10, 1),
        totalIncome: 10000.0,
        totalExpense: 6500.0,
        netSavings: 3500.0,
        categoryExpenses: {'cat_food': 1500.0, 'cat_rent': 5000.0},
      );

      expect(summary.savingsRate, equals(35.0));
      expect(summary.netSavings, equals(3500.0));

      final zeroIncomeSummary = MonthlySummary(
        month: DateTime(2026, 10, 1),
        totalIncome: 0.0,
        totalExpense: 500.0,
        netSavings: -500.0,
        categoryExpenses: {},
      );
      expect(zeroIncomeSummary.savingsRate, equals(0.0));
    });

    test('CategoryComparison delta calculation (Fase 3)', () {
      const cat = Category(
        id: 'cat1',
        name: 'Alimentação',
        type: TransactionType.expense,
        colorValue: 0xFFF97316,
        iconName: 'restaurant',
      );

      const comparison = CategoryComparison(
        category: cat,
        baseAmount: 1000.0,
        compareAmount: 1200.0,
        diffAmount: 200.0,
        diffPercent: 20.0,
      );

      expect(comparison.diffAmount, equals(200.0));
      expect(comparison.diffPercent, equals(20.0));
    });

    test('OfxParser parses SGML/XML statement correctly (Fase 4)', () {
      const ofxSample = '''
OFXHEADER:100
DATA:OFXSGML
<OFX>
<BANKTRANLIST>
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20261025120000[-03:EST]
<TRNAMT>-85.50
<FITID>20261025001
<MEMO>SUPERMERCADO DIA
</STMTTRN>
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20261026120000[-03:EST]
<TRNAMT>2500.00
<FITID>20261026002
<MEMO>SALARIO RECEBIDO
</STMTTRN>
</BANKTRANLIST>
</OFX>
''';

      const categories = [
        Category(id: 'c1', name: 'Alimentação', type: TransactionType.expense, colorValue: 0, iconName: ''),
        Category(id: 'c2', name: 'Salário & Remuneração', type: TransactionType.income, colorValue: 0, iconName: ''),
      ];

      final results = OfxParser.parse(
        ofxSample,
        availableCategories: categories,
        existingTransactions: [],
      );

      expect(results.length, equals(2));
      expect(results[0].description, equals('SUPERMERCADO DIA'));
      expect(results[0].amount, equals(85.50));
      expect(results[0].type, equals(TransactionType.expense));
      expect(results[0].date.year, equals(2026));
      expect(results[0].date.month, equals(10));
      expect(results[0].date.day, equals(25));
      expect(results[0].fitId, equals('20261025001'));
      expect(results[0].categoryId, equals('c1'));

      expect(results[1].description, equals('SALARIO RECEBIDO'));
      expect(results[1].amount, equals(2500.00));
      expect(results[1].type, equals(TransactionType.income));
      expect(results[1].categoryId, equals('c2'));
    });

    test('CsvBankParser parses bank CSV statement correctly (Fase 4)', () {
      const csvSample = '''
Data;Descricao;Valor
20/10/2026;Posto Shell;-150,00
21/10/2026;Pix Recebido;400,00
''';

      const categories = [
        Category(id: 'c1', name: 'Transporte', type: TransactionType.expense, colorValue: 0, iconName: ''),
        Category(id: 'c2', name: 'Outras Receitas', type: TransactionType.income, colorValue: 0, iconName: ''),
      ];

      final results = CsvBankParser.parse(
        csvSample,
        availableCategories: categories,
        existingTransactions: [],
      );

      expect(results.length, equals(2));
      expect(results[0].description, equals('Posto Shell'));
      expect(results[0].amount, equals(150.00));
      expect(results[0].type, equals(TransactionType.expense));
      expect(results[0].date.day, equals(20));

      expect(results[1].description, equals('Pix Recebido'));
      expect(results[1].amount, equals(400.00));
      expect(results[1].type, equals(TransactionType.income));
    });

    test('ExportCsvGenerator generates structured CSV for accounting (Fase 4)', () {
      final tx = TransactionItem(
        id: '1',
        accountId: 'acc1',
        categoryId: 'cat1',
        description: 'Padaria',
        amount: 32.50,
        date: DateTime(2026, 10, 28),
        type: TransactionType.expense,
      );

      const catMap = {
        'cat1': Category(id: 'cat1', name: 'Alimentação', type: TransactionType.expense, colorValue: 0, iconName: ''),
      };
      const accMap = {
        'acc1': Account(id: 'acc1', name: 'Nubank', type: AccountType.checking),
      };

      final csv = ExportCsvGenerator.generateCsv(
        transactions: [tx],
        categoryMap: catMap,
        accountMap: accMap,
      );

      expect(csv, startsWith('\uFEFFData;Tipo;Descrição;Categoria;Conta;Valor (R\$);Status;Parcelamento;Observações'));
      expect(csv, contains('28/10/2026;Despesa;Padaria;Alimentação;Nubank;32,50;Pago / Consolidado;À vista'));
    });

    test('NotificationService detects test environment safely (Fase 5)', () async {
      expect(NotificationService.isTestEnvironment, isTrue);
      await NotificationService.instance.init();
      final granted = await NotificationService.instance.requestPermissions();
      expect(granted, isTrue);
    });

    test('WidgetService detects test environment and safely skips platform channels (Fase 5)', () async {
      expect(WidgetService.isTestEnvironment, isTrue);
      await WidgetService.instance.init();
      await WidgetService.instance.updateWidgetData(
        totalBalance: 4500.00,
        monthlyExpense: 2300.00,
        userName: 'Investidor',
      );
    });
  });

  group('Financeiro Widget Tests (Fase 6)', () {
    testWidgets('SummaryCard renders title, formatted amount and accessible semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Saldo Geral',
              amount: 5432.10,
              icon: Icons.account_balance_wallet,
              accentColor: Colors.green,
              subtitle: 'Disponível em todas as contas',
            ),
          ),
        ),
      );

      expect(find.text('Saldo Geral'), findsOneWidget);
      expect(find.textContaining('5.432,10'), findsOneWidget);
      expect(find.text('Disponível em todas as contas'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);

      // Verify Semantics
      expect(
        tester.getSemantics(find.byType(SummaryCard)),
        matchesSemantics(
          label: 'Saldo Geral: ${CurrencyFormatter.format(5432.10)}',
          isReadOnly: true,
        ),
      );
    });
  });
}
