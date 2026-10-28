import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FinStatsAppIcon extends StatelessWidget {
  final double size;

  const FinStatsAppIcon({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald, AppColors.emeraldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldDark.withValues(alpha: 0.25),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.52,
          color: Colors.white,
        ),
      ),
    );
  }
}
