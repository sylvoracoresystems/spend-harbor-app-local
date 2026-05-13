import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/import_controller.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  bool _busy = false;
  ImportSummary? _result;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(l.importTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.importHint,
              style: AppTypography.sm.copyWith(color: c.textBody),
            ),
            const SizedBox(height: AppSpacing.x4),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.upload),
              label: Text(l.importPickCsv),
              onPressed: _busy ? null : _run,
            ),
            if (_result != null) ...[
              const SizedBox(height: AppSpacing.x4),
              Text(
                l.importSummary(
                  _result!.parsed,
                  _result!.imported,
                  _result!.duplicates,
                  _result!.invalid,
                ),
                style: AppTypography.sm.copyWith(color: c.actionInk),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _run() async {
    final l = AppL10n.of(context);
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final summary = await importCsvFromPicker(ref: ref, l: l);
      if (!mounted) return;
      setState(() => _result = summary);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
