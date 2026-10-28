import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IosDivider extends StatelessWidget {
  final double indent;
  final double endIndent;

  const IosDivider({
    super.key,
    this.indent = 56.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: indent,
      endIndent: endIndent,
      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
    );
  }
}
