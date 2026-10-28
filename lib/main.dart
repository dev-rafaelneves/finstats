import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  final appState = AppState();
  await appState.init();
  runApp(FinanceiroApp(appState: appState));
}

class FinanceiroApp extends StatelessWidget {
  final AppState appState;

  const FinanceiroApp({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Financeiro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('pt', 'BR'),
          home: _RootRouter(appState: appState),
        );
      },
    );
  }
}

class _RootRouter extends StatelessWidget {
  final AppState appState;

  const _RootRouter({required this.appState});

  @override
  Widget build(BuildContext context) {
    if (!appState.onboardingDone) {
      return OnboardingScreen(appState: appState);
    }

    return AppLockGate(
      appState: appState,
      child: MainShell(appState: appState),
    );
  }
}
