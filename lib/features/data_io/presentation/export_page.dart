import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../transactions/application/transactions_list_controller.dart';
import '../application/export_controller.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ym = ref.watch(currentMonthProvider);
    final txAsync = ref.watch(transactionsOfMonthProvider);
    final isEmpty = (txAsync.valueOrNull ?? const []).isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l.exportTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.exportMonthHint(ym.key),
              style: AppTypography.sm.copyWith(color: c.textBody),
            ),
            const SizedBox(height: AppSpacing.x4),
            if (isEmpty)
              Text(
                l.exportEmpty,
                style: AppTypography.xs.copyWith(color: c.textMuted),
              ),
            const Spacer(),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.download),
              label: Text(l.exportButton),
              onPressed: (_busy || isEmpty) ? null : _runExport,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runExport() async {
    setState(() => _busy = true);
    try {
      final l = AppL10n.of(context);
      await exportCurrentMonthToCsv(ref: ref, l: l);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.exportDone)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
