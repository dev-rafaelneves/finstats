import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../utils/currency_formatter.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const String appGroupId = 'group.com.financeiro.app';
  static const String androidWidgetProvider = 'FinanceiroWidgetProvider';
  static const String iOSWidgetName = 'FinanceiroWidget';

  static bool get isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    if (kIsWeb || isTestEnvironment || !isSupportedPlatform) return;

    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Aviso ao inicializar HomeWidget: $e');
    }
  }

  /// Sincroniza dados com o widget compacto da tela inicial
  Future<void> updateWidgetData({
    required double totalBalance,
    required double monthlyExpense,
    String? userName,
  }) async {
    if (kIsWeb || isTestEnvironment || !isSupportedPlatform) return;

    try {
      await HomeWidget.saveWidgetData<String>(
        'total_balance',
        CurrencyFormatter.format(totalBalance),
      );
      await HomeWidget.saveWidgetData<String>(
        'monthly_expense',
        CurrencyFormatter.format(monthlyExpense),
      );
      await HomeWidget.saveWidgetData<String>(
        'user_name',
        userName ?? 'Usuário',
      );
      await HomeWidget.saveWidgetData<String>(
        'last_update',
        'Atualizado às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      );

      // Deep link para abrir direto novo lançamento ao tocar no widget
      await HomeWidget.registerInteractivityCallback(_backgroundCallback);

      await HomeWidget.updateWidget(
        name: androidWidgetProvider,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('Aviso ao atualizar widget: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    // Callback nativo em segundo plano se acionado por botão interativo do widget
    if (uri != null) {
      debugPrint('Widget acionado com URI: $uri');
    }
  }
}
