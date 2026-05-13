import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/source_form_controller.dart';

class SourceEditPage extends ConsumerStatefulWidget {
  const SourceEditPage({super.key, this.id});
  final String? id;

  @override
  ConsumerState<SourceEditPage> createState() => _SourceEditPageState();
}

class _SourceEditPageState extends ConsumerState<SourceEditPage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    ref.listenManual<SourceFormState>(_provider(), (prev, next) {
      if (prev?.name != next.name && _nameCtrl.text != next.name) {
        _nameCtrl.text = next.name;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  AutoDisposeStateNotifierProvider<SourceFormController, SourceFormState>
      _provider() =>
          sourceFormControllerProvider(widget.id);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final state = ref.watch(_provider());
    final notifier = ref.read(_provider().notifier);
    final color = _hexToColor(state.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing ? l.srcEditTitle : l.srcNewTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: [
          TextField(
            controller: _nameCtrl,
            maxLength: 80,
            decoration: InputDecoration(labelText: l.catFieldName),
            onChanged: notifier.setName,
          ),
          const SizedBox(height: AppSpacing.x4),
          DropdownButtonFormField<String>(
            value: state.currency,
            decoration: InputDecoration(labelText: l.srcFieldCurrency),
            items: [
              for (final ccy in Currency.all)
                DropdownMenuItem(
                  value: ccy.code,
                  child: Text(_currencyLabel(context, ccy)),
                ),
            ],
            onChanged: (v) {
              if (v != null) notifier.setCurrency(v);
            },
          ),
          const SizedBox(height: AppSpacing.x4),
          _SectionLabel(text: l.catFieldIcon),
          const SizedBox(height: AppSpacing.x2),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final entry in kIconRegistry.entries)
                GestureDetector(
                  onTap: () => notifier.setIcon(entry.key),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: state.icon == entry.key
                          ? color.withValues(alpha: 0.18)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: AppRadius.brFull,
                      border: Border.all(
                        color: state.icon == entry.key
                            ? color
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Icon(entry.value, size: 18, color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          _SectionLabel(text: l.catFieldColor),
          const SizedBox(height: AppSpacing.x2),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final hex in kPaletteHex)
                GestureDetector(
                  onTap: () => notifier.setColor(hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: state.color == hex ? 3 : 1,
                        color: state.color == hex
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          FilledButton(
            onPressed: state.submitting
                ? null
                : () async {
                    final err = await notifier.submit();
                    if (!context.mounted) return;
                    if (err == null) {
                      Navigator.of(context).pop(true);
                      return;
                    }
                    final msg = switch (err) {
                      SourceFormError.nameRequired => l.srcErrNameRequired,
                      SourceFormError.nameDuplicate => l.srcErrNameDuplicate,
                    };
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  },
            child: Text(l.txSave),
          ),
          if (state.isEditing) ...[
            const SizedBox(height: AppSpacing.x3),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: c.expense),
              onPressed: state.submitting
                  ? null
                  : () => _confirmDelete(context, notifier),
              child: Text(l.txDelete),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SourceFormController notifier,
  ) async {
    final l = AppL10n.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.srcDeleteConfirmTitle),
        content: Text(l.srcDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.txCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.txDelete),
          ),
        ],
      ),
    );
    if (yes == true) {
      await notifier.delete();
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }
}

String _currencyLabel(BuildContext context, Currency ccy) {
  final isZh = Localizations.localeOf(context).languageCode == 'zh';
  final name = isZh ? ccy.chineseName : ccy.englishName;
  return '${ccy.code} · ${ccy.symbol} · $name';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Text(
      text,
      style: AppTypography.xs.copyWith(
        color: c.textMuted,
        fontWeight: AppTypography.weightMedium,
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
