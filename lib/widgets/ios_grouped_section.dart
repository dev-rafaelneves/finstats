import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ios_divider.dart';

class IosGroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;

  const IosGroupedSection({
    super.key,
    this.header,
    this.footer,
    this.child,
    this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.contentPadding,
    this.backgroundColor,
  }) : assert(child != null || children != null, 'Either child or children must be provided');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = backgroundColor ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final headerColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Widget content;
    if (children != null) {
      final items = <Widget>[];
      for (int i = 0; i < children!.length; i++) {
        items.add(children![i]);
        if (i < children!.length - 1) {
          items.add(const IosDivider());
        }
      }
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      );
    } else {
      content = child!;
    }

    if (contentPadding != null) {
      content = Padding(
        padding: contentPadding!,
        child: content,
      );
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 6),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: headerColor,
                ),
              ),
            ),
          ],
          Material(
            color: cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: BorderSide(color: borderColor, width: 0.8),
            ),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 6),
              child: Text(
                footer!,
                style: TextStyle(
                  fontSize: 11.5,
                  color: headerColor,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
