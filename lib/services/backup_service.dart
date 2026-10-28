import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

class BackupService {
  static Future<String> generateBackupJson() async {
    final data = await DatabaseService.exportAllData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Future<void> shareBackupFile() async {
    final jsonStr = await generateBackupJson();
    final fileName = 'backup_financeiro_${DateTime.now().millisecondsSinceEpoch}.json';
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));

    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/json', name: fileName)],
      subject: 'Backup Financeiro Pessoal',
      text: 'Arquivo de backup confidencial das finanças pessoais.',
    );
  }

  static Future<bool> restoreFromJsonString(String jsonContent) async {
    try {
      final decoded = json.decode(jsonContent) as Map<String, dynamic>;
      if (!decoded.containsKey('user_profile') && !decoded.containsKey('transactions')) {
        return false;
      }
      await DatabaseService.restoreAllData(decoded);
      return true;
    } catch (_) {
      return false;
    }
  }
}
