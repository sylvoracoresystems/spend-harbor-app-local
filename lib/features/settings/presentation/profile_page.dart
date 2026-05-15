import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(profileNicknameProvider));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final nickname = ref.watch(profileNicknameProvider);
    return SubPageScaffold(
      title: l.settingsProfile,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.action.withValues(alpha: 0.15),
                borderRadius: AppRadius.brFull,
              ),
              alignment: Alignment.center,
              child: Text(
                initialsFor(nickname),
                style: AppTypography.xxl.copyWith(
                  color: c.action,
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _ctrl,
            maxLength: 40,
            decoration: InputDecoration(labelText: l.profileFieldNickname),
            onChanged: (v) =>
                ref.read(profileNicknameProvider.notifier).setNickname(v),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l.profileNicknameHint,
            style: AppTypography.xs.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
