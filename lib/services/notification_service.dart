import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _dailyReminderId = 1001;
  static const String _channelId = 'financeiro_reminders';
  static const String _channelName = 'Lembretes Financeiros';
  static const String _channelDesc = 'Notificações de despesas diárias, vencimentos e fechamento de faturas';

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
    if (kIsWeb || isTestEnvironment) {
      _isInitialized = true;
      return;
    }
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb || isTestEnvironment) return true;
    try {
      if (isSupportedPlatform && Platform.isAndroid) {
        final android = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      } else if (isSupportedPlatform && Platform.isIOS) {
        final ios = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> scheduleDailyExpenseReminder({required int hour, required int minute}) async {
    if (kIsWeb || isTestEnvironment || !_isInitialized) return;

    try {
      await cancelDailyExpenseReminder();

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _notificationsPlugin.zonedSchedule(
        id: _dailyReminderId,
        title: 'Registro Financeiro Diário 💰',
        body: 'Não esqueça de registrar suas despesas e receitas de hoje para manter seu saldo em dia!',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Erro ao agendar lembrete diário: $e');
    }
  }

  Future<void> cancelDailyExpenseReminder() async {
    if (kIsWeb || isTestEnvironment) return;
    try {
      await _notificationsPlugin.cancel(id: _dailyReminderId);
    } catch (_) {}
  }

  Future<void> scheduleBillReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb || isTestEnvironment || !_isInitialized) return;

    try {
      final now = tz.TZDateTime.now(tz.local);
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      if (tzDate.isBefore(now)) return;

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Erro ao agendar notificação de vencimento: $e');
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || isTestEnvironment) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();

      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      debugPrint('Erro ao exibir notificação imediata: $e');
    }
  }
}
