import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';

class AppLockGate extends StatefulWidget {
  final AppState appState;
  final Widget child;

  const AppLockGate({
    super.key,
    required this.appState,
    required this.child,
  });

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool _isUnlocked = false;
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    if (!widget.appState.hasPinLock) {
      setState(() => _isUnlocked = true);
      return;
    }

    // Try biometrics automatically if enabled
    if (widget.appState.userProfile?.useBiometrics == true) {
      final authenticated = await SecurityService.authenticateWithBiometrics();
      if (authenticated && mounted) {
        setState(() => _isUnlocked = true);
      }
    }
  }

  void _onDigitPress(String digit) {
    if (_pinController.text.length < 4) {
      HapticFeedback.selectionClick();
      setState(() {
        _pinController.text += digit;
        _errorMessage = '';
      });

      if (_pinController.text.length == 4) {
        _validatePin();
      }
    }
  }

  void _onBackspace() {
    if (_pinController.text.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _validatePin() async {
    final valid = await SecurityService.verifyPin(_pinController.text);
    if (valid) {
      HapticFeedback.mediumImpact();
      setState(() => _isUnlocked = true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PIN incorreto. Tente novamente.';
        _pinController.clear();
      });
    }
  }

  Future<void> _tryBiometrics() async {
    final authenticated = await SecurityService.authenticateWithBiometrics();
    if (authenticated && mounted) {
      HapticFeedback.mediumImpact();
      setState(() => _isUnlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked || !widget.appState.hasPinLock) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 36,
                  color: AppColors.emeraldDark,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Financeiro Seguro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Digite seu PIN de 4 dígitos para desbloquear',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _pinController.text.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? AppColors.emeraldDark
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  );
                }),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: AppColors.rose, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],

              const Spacer(),

              // Numeric Keypad (Apple HIG style)
              _buildKeypad(isDark),
              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: _tryBiometrics,
                icon: const Icon(Icons.fingerprint, color: AppColors.emeraldDark),
                label: const Text(
                  'Usar Biometria',
                  style: TextStyle(color: AppColors.emeraldDark, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((d) => _buildKey(d, isDark)).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 68, height: 68),
              _buildKey('0', isDark),
              SizedBox(
                width: 68,
                height: 68,
                child: IconButton(
                  icon: Icon(
                    Icons.backspace_outlined,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  onPressed: _onBackspace,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String digit, bool isDark) {
    final keyBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: keyBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: () => _onDigitPress(digit),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
