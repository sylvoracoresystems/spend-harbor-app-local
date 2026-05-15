import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums/transaction_type.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../shared/widgets/color_grid.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../shared/widgets/transaction_type_toggle.dart';
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
          categoryFormControllerProvider((widget.id, widget.initialType));

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final state = ref.watch(_provider());
    final notifier = ref.read(_provider().notifier);

    return SubPageScaffold(
      title: state.isEditing ? l.catEditTitle : l.catNewTitle,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PreviewCard(
                icon: iconFor(state.icon),
                color: _hexToColor(state.color),
                name: state.name,
                placeholder: l.catFieldName,
              ),
              const SizedBox(height: AppSpacing.x4),
              TransactionTypeToggle(
                value: state.type,
                onChanged: notifier.setType,
              ),
              const SizedBox(height: AppSpacing.x4),
              TextField(
                controller: _nameCtrl,
                maxLength: 80,
                decoration: InputDecoration(labelText: l.catFieldName),
                onChanged: notifier.setName,
              ),
              const SizedBox(height: AppSpacing.x4),
              _SectionLabel(text: l.catFieldColor),
              const SizedBox(height: AppSpacing.x2),
              ColorGrid(value: state.color, onPicked: notifier.setColor),
              const SizedBox(height: AppSpacing.x4),
              _SectionLabel(text: l.catFieldIcon),
              const SizedBox(height: AppSpacing.x2),
              Expanded(
                child: _IconPicker(
                  value: state.icon,
                  color: _hexToColor(state.color),
                  onPicked: notifier.setIcon,
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
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
                          CategoryFormError.nameRequired =>
                            l.catErrNameRequired,
                          CategoryFormError.nameDuplicate =>
                            l.catErrNameDuplicate,
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
        ),
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.icon,
    required this.color,
    required this.name,
    required this.placeholder,
  });
  final IconData icon;
  final Color color;
  final String name;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final showPlaceholder = name.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        boxShadow: [
          BoxShadow(
            color: c.actionInk.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: c.actionInk.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              showPlaceholder ? placeholder : name,
              style: AppTypography.base.copyWith(
                color: showPlaceholder ? c.textMuted : c.actionInk,
                fontWeight: AppTypography.weightSemibold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
    final c = context.appColors;
    final entries = kIconRegistry.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 48,
          mainAxisSpacing: AppSpacing.x2,
          crossAxisSpacing: AppSpacing.x2,
          childAspectRatio: 1,
        ),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          final selected = value == entry.key;
          return GestureDetector(
            onTap: () => onPicked(entry.key),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? color : c.surfacePress,
                borderRadius: AppRadius.brFull,
                border: Border.all(color: selected ? color : c.border),
              ),
              child: Icon(
                entry.value,
                size: 18,
                color: selected ? Colors.white : c.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
