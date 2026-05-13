import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums/transaction_type.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/category_form_controller.dart';

class CategoryEditPage extends ConsumerStatefulWidget {
  const CategoryEditPage({super.key, this.id, this.initialType});

  final String? id;

  /// 新建时由 CategoriesPage 通过 extra 传入当前 tab 类型。
  final TransactionType? initialType;

  @override
  ConsumerState<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends ConsumerState<CategoryEditPage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    final notifier = ref.read(_provider().notifier);
    if (widget.id == null && widget.initialType != null) {
      notifier.setType(widget.initialType!);
    }
    ref.listenManual<CategoryFormState>(_provider(), (prev, next) {
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

  AutoDisposeStateNotifierProvider<CategoryFormController, CategoryFormState>
      _provider() =>
          categoryFormControllerProvider(widget.id);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final state = ref.watch(_provider());
    final notifier = ref.read(_provider().notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing ? l.catEditTitle : l.catNewTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: [
          SegmentedButton<TransactionType>(
            segments: [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text(l.txTypeExpense),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text(l.txTypeIncome),
              ),
            ],
            selected: {state.type},
            onSelectionChanged: (s) => notifier.setType(s.first),
          ),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: _nameCtrl,
            maxLength: 80,
            decoration: InputDecoration(labelText: l.catFieldName),
            onChanged: notifier.setName,
          ),
          const SizedBox(height: AppSpacing.x4),
          _SectionLabel(text: l.catFieldIcon),
          const SizedBox(height: AppSpacing.x2),
          _IconPicker(
            value: state.icon,
            color: _hexToColor(state.color),
            onPicked: notifier.setIcon,
          ),
          const SizedBox(height: AppSpacing.x4),
          _SectionLabel(text: l.catFieldColor),
          const SizedBox(height: AppSpacing.x2),
          _ColorPicker(value: state.color, onPicked: notifier.setColor),
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
                      CategoryFormError.nameRequired => l.catErrNameRequired,
                      CategoryFormError.nameDuplicate => l.catErrNameDuplicate,
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
    CategoryFormController notifier,
  ) async {
    final l = AppL10n.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.catDeleteConfirmTitle),
        content: Text(l.catDeleteConfirmBody),
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

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.value,
    required this.color,
    required this.onPicked,
  });
  final String value;
  final Color color;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        for (final entry in kIconRegistry.entries)
          GestureDetector(
            onTap: () => onPicked(entry.key),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: value == entry.key
                    ? color.withValues(alpha: 0.18)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.brFull,
                border: Border.all(
                  color: value == entry.key
                      ? color
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Icon(entry.value, size: 18, color: color),
            ),
          ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.value, required this.onPicked});
  final String value;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        for (final hex in kPaletteHex)
          GestureDetector(
            onTap: () => onPicked(hex),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _hexToColor(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  width: value == hex ? 3 : 1,
                  color: value == hex
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
