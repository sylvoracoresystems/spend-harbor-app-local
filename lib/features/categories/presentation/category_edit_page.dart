import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums/transaction_type.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/icons/icon_registry.dart';
import '../../../shared/utils/hex_color.dart';
import '../../../shared/utils/synced_text_controller.dart';
import '../../../shared/widgets/color_grid.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/icon_picker.dart';
import '../../../shared/widgets/preview_card.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/transaction_type_toggle.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../application/category_form_controller.dart';

/// 分类新建/编辑页：`id` 为空走新建，`initialType` 决定新建的收/支默认值。
class CategoryEditPage extends ConsumerStatefulWidget {
  const CategoryEditPage({super.key, this.id, this.initialType});

  final String? id;

  /// 新建时由 CategoriesPage 通过 extra 传入当前 tab 类型。
  final TransactionType? initialType;

  @override
  ConsumerState<CategoryEditPage> createState() => _CategoryEditPageState();
}

/// 持有名称 TextEditingController 并与 controller state 双向同步。
class _CategoryEditPageState extends ConsumerState<CategoryEditPage> {
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

  AutoDisposeStateNotifierProvider<CategoryFormController, CategoryFormState>
      _provider() =>
          categoryFormControllerProvider((widget.id, widget.initialType));

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final state = ref.watch(_provider());
    final notifier = ref.read(_provider().notifier);

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SubPageScaffold(
      title: state.isEditing ? l.catEditTitle : l.catNewTitle,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x4,
            AppSpacing.x4,
            AppSpacing.x6 + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PreviewCard(
                icon: iconFor(state.icon),
                color: HexColor.fromHex(state.color),
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
              SectionLabel(l.catFieldColor),
              const SizedBox(height: AppSpacing.x2),
              ColorGrid(value: state.color, onPicked: notifier.setColor),
              const SizedBox(height: AppSpacing.x4),
              SectionLabel(l.catFieldIcon),
              const SizedBox(height: AppSpacing.x2),
              SizedBox(
                height: 240,
                child: IconPicker(
                  value: state.icon,
                  color: HexColor.fromHex(state.color),
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
    final ok = await showConfirmDialog(
      context,
      title: l.catDeleteConfirmTitle,
      body: l.catDeleteConfirmBody,
    );
    if (!ok) return;
    await notifier.delete();
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
