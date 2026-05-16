import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/color_grid.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
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

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SubPageScaffold(
      title: state.isEditing ? l.tagEditTitle : l.tagNewTitle,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x6 + bottomInset,
        ),
        children: [
          _PreviewCard(
            color: _hexToColor(state.color),
            name: state.name,
            placeholder: l.catFieldName,
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.color,
    required this.name,
    required this.placeholder,
  });
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
            child: Icon(LucideIcons.tag, size: 28, color: Colors.white),
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

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('ff$cleaned', radix: 16));
}
