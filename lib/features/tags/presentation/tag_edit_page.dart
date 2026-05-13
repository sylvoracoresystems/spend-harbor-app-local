import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/tag_form_controller.dart';

class TagEditPage extends ConsumerStatefulWidget {
  const TagEditPage({super.key, this.id});
  final String? id;

  @override
  ConsumerState<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends ConsumerState<TagEditPage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    ref.listenManual<TagFormState>(_provider(), (prev, next) {
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

  AutoDisposeStateNotifierProvider<TagFormController, TagFormState>
      _provider() =>
          tagFormControllerProvider(widget.id);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final state = ref.watch(_provider());
    final notifier = ref.read(_provider().notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing ? l.tagEditTitle : l.tagNewTitle),
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
          Text(
            l.catFieldColor,
            style: AppTypography.xs.copyWith(
              color: c.textMuted,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
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
                      TagFormError.nameRequired => l.tagErrNameRequired,
                      TagFormError.nameDuplicate => l.tagErrNameDuplicate,
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
    TagFormController notifier,
  ) async {
    final l = AppL10n.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tagDeleteConfirmTitle),
        content: Text(l.tagDeleteConfirmBody),
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

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
