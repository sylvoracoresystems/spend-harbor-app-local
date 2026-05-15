import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

const _kAppVersion = '1.0.0';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAbout)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x6),
        children: [
          Center(
            child: Column(
              children: [
                Icon(LucideIcons.wallet, size: 72, color: c.action),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  l.appName,
                  style: AppTypography.xxxl.copyWith(
                    color: c.actionInk,
                    fontWeight: AppTypography.weightSemibold,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  l.aboutVersion(_kAppVersion),
                  style: AppTypography.xs.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  l.aboutTagline,
                  textAlign: TextAlign.center,
                  style: AppTypography.sm.copyWith(color: c.textBody),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(
            l.aboutDescription,
            style: AppTypography.sm.copyWith(color: c.textBody),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            l.aboutCreditsTitle,
            style: AppTypography.sm.copyWith(
              color: c.actionInk,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l.aboutCreditsBody,
            style: AppTypography.xs.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
