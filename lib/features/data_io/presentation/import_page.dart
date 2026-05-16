import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/import_controller.dart';
import '../application/taxonomy_import_controller.dart';
import '../application/xlsx_codec.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  bool _busy = false;
  bool _allowDuplicates = false;
  ImportSummary? _txResult;
  TaxonomyImportSummary? _taxResult;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return SubPageScaffold(
      title: l.importTitle,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.importHint,
              style: AppTypography.sm.copyWith(color: c.textBody),
            ),
            const SizedBox(height: AppSpacing.x3),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _allowDuplicates,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _allowDuplicates = v),
              title: Text(
                l.importAllowDuplicatesLabel,
                style: AppTypography.sm.copyWith(color: c.textPrimary),
              ),
              subtitle: Text(
                l.importAllowDuplicatesHint,
                style: AppTypography.xs.copyWith(color: c.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.upload),
              label: Text(l.importPickFile),
              onPressed: _busy ? null : _run,
            ),
            if (_txResult != null) ...[
              const SizedBox(height: AppSpacing.x4),
              Text(
                l.importTxSummary(
                  _txResult!.parsed,
                  _txResult!.imported,
                  _txResult!.duplicates,
                  _txResult!.invalid,
                ),
                style: AppTypography.sm.copyWith(color: c.actionInk),
              ),
              if (_txResult!.autoCreatedCategories +
                      _txResult!.autoCreatedTags +
                      _txResult!.autoCreatedSources >
                  0) ...[
                const SizedBox(height: AppSpacing.x2),
                Text(
                  l.importTxAutoCreated(
                    _txResult!.autoCreatedCategories,
                    _txResult!.autoCreatedTags,
                    _txResult!.autoCreatedSources,
                  ),
                  style: AppTypography.xs.copyWith(color: c.textMuted),
                ),
              ],
            ],
            if (_taxResult != null) ...[
              const SizedBox(height: AppSpacing.x4),
              Text(
                l.importTaxonomySummary(
                  _taxResult!.categoriesAdded,
                  _taxResult!.categoriesUpdated,
                  _taxResult!.categoriesDeleted,
                  _taxResult!.tagsAdded,
                  _taxResult!.tagsUpdated,
                  _taxResult!.tagsDeleted,
                  _taxResult!.sourcesAdded,
                  _taxResult!.sourcesUpdated,
                  _taxResult!.sourcesDeleted,
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
      _txResult = null;
      _taxResult = null;
    });
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final path = file.path;
      if (path == null) return;
      final ext = (file.extension ?? '').toLowerCase();

      if (ext == 'csv') {
        final body = await File(path).readAsString();
        final summary = await importCsvFromString(
          ref: ref, l: l, body: body, allowDuplicates: _allowDuplicates);
        if (!mounted) return;
        setState(() => _txResult = summary);
        return;
      }

      // xlsx：根据 sheet 结构判断是 taxonomy 还是 transactions
      final bytes = await File(path).readAsBytes();
      final kind = _detectXlsxKind(bytes);
      switch (kind) {
        case _XlsxKind.taxonomy:
          if (!mounted) return;
          final ok = await _confirmTaxonomyImport(context);
          if (ok != true) return;
          if (!mounted) return;
          final summary = await importTaxonomyFromBytes(
            ref: ref,
            l: l,
            bytes: bytes,
          );
          if (!mounted) return;
          setState(() => _taxResult = summary);
        case _XlsxKind.transactions:
          final summary = await importTransactionsFromXlsx(
            ref: ref,
            l: l,
            bytes: bytes,
            allowDuplicates: _allowDuplicates,
          );
          if (!mounted) return;
          setState(() => _txResult = summary);
        case _XlsxKind.unknown:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Unrecognized xlsx structure')),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmTaxonomyImport(BuildContext context) async {
    final l = AppL10n.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.importTaxonomyConfirmTitle),
        content: Text(l.importTaxonomyConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.txCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.txSave),
          ),
        ],
      ),
    );
  }
}

enum _XlsxKind { taxonomy, transactions, unknown }

_XlsxKind _detectXlsxKind(Uint8List bytes) {
  try {
    final sheets = decodeXlsx(bytes);
    final names = sheets.map((s) => s.name.toLowerCase()).toSet();
    if (names.contains('categories') || names.contains('tags') ||
        names.contains('sources')) {
      return _XlsxKind.taxonomy;
    }
    if (names.contains('transactions')) {
      return _XlsxKind.transactions;
    }
    return _XlsxKind.unknown;
  } catch (_) {
    return _XlsxKind.unknown;
  }
}
