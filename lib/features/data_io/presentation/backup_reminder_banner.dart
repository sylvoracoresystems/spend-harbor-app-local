import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/backup_reminder.dart';

/// 备份提醒横幅。
///
/// - 从未备份 / 超过阈值天数 → 橙色 / 红色高亮，点击跳备份页
/// - 阈值内 → 不渲染（[showAlways]=true 时只显示一行轻提示）
class BackupReminderBanner extends ConsumerWidget {
  const BackupReminderBanner({super.key, this.showAlways = false});

  /// `true` 时即便最近已备份也显示状态行（BackupPage 顶部用）。
  final bool showAlways;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final status = ref.watch(backupStatusProvider);

    if (!status.shouldRemind && !showAlways) {
      return const SizedBox.shrink();
    }

    final remind = status.shouldRemind;
    final bg = remind ? c.expenseSoft : c.mintSoft;
    final fg = remind ? c.expense : c.actionInk;

    String label;
    if (status.lastBackupAt == null) {
      label = l.backupNever;
    } else if (remind) {
      label = l.backupOverdue(status.daysSince ?? 0);
    } else {
      label = l.backupRecent(status.daysSince ?? 0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x2,
      ),
      child: InkWell(
        borderRadius: AppRadius.brXl,
        onTap: () => context.push('/settings/backup'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x3,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brXl,
          ),
          child: Row(
            children: [
              Icon(
                remind ? LucideIcons.alertTriangle : LucideIcons.check,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.xs.copyWith(
                    color: fg,
                    fontWeight: AppTypography.weightMedium,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
