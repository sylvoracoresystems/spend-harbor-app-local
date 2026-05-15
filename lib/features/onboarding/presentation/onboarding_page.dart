import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/onboarding_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(LucideIcons.wallet, size: 72, color: c.action),
              const SizedBox(height: AppSpacing.x6),
              Text(
                l.onboardingTitle,
                textAlign: TextAlign.center,
                style: AppTypography.xxxl.copyWith(
                  color: c.actionInk,
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Text(
                l.onboardingSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(onboardingControllerProvider.notifier)
                      .markDone();
                  if (!context.mounted) return;
                  context.go('/');
                },
                child: Text(l.onboardingGetStarted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
