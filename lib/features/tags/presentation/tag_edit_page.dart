import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/utils/hex_color.dart';
import '../../../shared/utils/synced_text_controller.dart';
import '../../../shared/widgets/color_grid.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/preview_card.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
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
    _nameCtrl = syncedTextController(
      ref: ref,
      provider: _provider(),
      selector: (s) => s.name,
    );
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
          PreviewCard(
            icon: LucideIcons.tag,
            color: HexColor.fromHex(state.color),
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
          SectionLabel(l.catFieldColor),
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
    final ok = await showConfirmDialog(
      context,
      title: l.tagDeleteConfirmTitle,
      body: l.tagDeleteConfirmBody,
    );
    if (!ok) return;
    await notifier.delete();
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
