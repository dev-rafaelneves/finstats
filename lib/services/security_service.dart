import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();
  static const _pinKey = 'financeiro_secure_pin_hash';

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  static Future<bool> setPin(String pin) async {
    try {
      final hash = hashPin(pin);
      await _storage.write(key: _pinKey, value: hash);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      if (storedHash == null) return false;
      return storedHash == hashPin(pin);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPin() async {
    try {
      final hash = await _storage.read(key: _pinKey);
      return hash != null && hash.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> removePin() async {
    try {
      await _storage.delete(key: _pinKey);
    } catch (_) {}
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar suas finanças com segurança',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
