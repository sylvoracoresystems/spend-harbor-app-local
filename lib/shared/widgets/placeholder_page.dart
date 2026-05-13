import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 通用占位页：尚未实现的页面统一渲染。
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    this.showAppBar = true,
  });

  final String title;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = AppL10n.of(context);
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.construction, size: 56, color: c.textMuted),
            const SizedBox(height: AppSpacing.x4),
            Text(
              title,
              style: AppTypography.xl.copyWith(
                color: c.actionInk,
                fontWeight: AppTypography.weightSemibold,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              l.comingSoon,
              style: AppTypography.sm.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );

    if (!showAppBar) return body;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}
