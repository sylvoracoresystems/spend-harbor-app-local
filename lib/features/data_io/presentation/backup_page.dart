import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/backup_controller.dart';
import '../application/backup_serializer.dart';
import 'backup_reminder_banner.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _exporting = false;
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(l.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: [
          const BackupReminderBanner(showAlways: true),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l.backupExportHint,
            style: AppTypography.sm.copyWith(color: c.textBody),
          ),
          const SizedBox(height: AppSpacing.x3),
          FilledButton.icon(
            icon: _exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.archive),
            label: Text(l.backupExportButton),
            onPressed: (_exporting || _restoring) ? null : _runExport,
          ),
          const SizedBox(height: AppSpacing.x6),
          Divider(color: c.border, height: 1),
          const SizedBox(height: AppSpacing.x4),
          Text(
            l.backupRestoreHint,
            style: AppTypography.sm.copyWith(color: c.expense),
          ),
          const SizedBox(height: AppSpacing.x3),
          OutlinedButton.icon(
            icon: _restoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.uploadCloud),
            style: OutlinedButton.styleFrom(foregroundColor: c.expense),
            label: Text(l.backupRestoreButton),
            onPressed: (_exporting || _restoring) ? null : _runRestore,
          ),
        ],
      ),
    );
  }

  Future<void> _runExport() async {
    setState(() => _exporting = true);
    try {
      await exportBackup(ref: ref);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _runRestore() async {
    final l = AppL10n.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.backupRestoreConfirmTitle),
        content: Text(l.backupRestoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.txCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.backupRestoreButton),
          ),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _restoring = true);
    try {
      final ok = await restoreBackup(ref: ref);
      if (!mounted || !ok) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.backupRestoreDone)));
    } on BackupVersionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.backupVersionMismatch(e.found, e.expected)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }
}
