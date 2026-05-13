import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsLegal)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x6),
        children: [
          Text(
            l.legalPrivacyTitle,
            style: AppTypography.lg.copyWith(
              color: c.actionInk,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(l.legalPrivacyBody,
              style: AppTypography.sm.copyWith(color: c.textBody)),
          const SizedBox(height: AppSpacing.x6),
          Text(
            l.legalTermsTitle,
            style: AppTypography.lg.copyWith(
              color: c.actionInk,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(l.legalTermsBody,
              style: AppTypography.sm.copyWith(color: c.textBody)),
        ],
      ),
    );
  }
}
