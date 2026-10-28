import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_lock_gate.dart';
import '../widgets/bottom_nav_item.dart';
import '../widgets/quick_transaction_modal.dart';
import 'main_shell/dashboard_tab.dart';
import 'main_shell/planning_tab.dart';
import 'main_shell/settings_tab.dart';
import 'main_shell/transactions_tab.dart';

class MainShell extends StatefulWidget {
  final AppState appState;

  const MainShell({super.key, required this.appState});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  void _openNewTransaction() {
    QuickTransactionModal.show(context, appState: widget.appState);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.88);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final tabs = [
      DashboardTab(
        appState: widget.appState,
        onOpenNewTransaction: _openNewTransaction,
      ),
      TransactionsTab(
        appState: widget.appState,
        onOpenNewTransaction: _openNewTransaction,
      ),
      PlanningTab(appState: widget.appState),
      SettingsTab(appState: widget.appState),
    ];

    return AppLockGate(
      appState: widget.appState,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 83,
              decoration: BoxDecoration(
                color: navBg,
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                    width: 0.8,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    BottomNavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Início',
                      isSelected: _currentIndex == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = 0);
                      },
                    ),
                    BottomNavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Extrato',
                      isSelected: _currentIndex == 1,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    BottomNavItem(
                      icon: Icons.insights_rounded,
                      label: 'Metas & Análise',
                      isSelected: _currentIndex == 2,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = 2);
                      },
                    ),
                    BottomNavItem(
                      icon: Icons.settings_rounded,
                      label: 'Ajustes',
                      isSelected: _currentIndex == 3,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = 3);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
