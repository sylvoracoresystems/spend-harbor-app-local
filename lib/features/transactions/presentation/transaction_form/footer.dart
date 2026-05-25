part of '../transaction_form.dart';

/// 备注输入框：多行 + 500 字限长。
class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = AppL10n.of(context);
    return _OutlinedBox(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2 + 2,
      ),
      child: TextField(
        controller: controller,
        maxLines: 2,
        maxLength: 500,
        style: AppTypography.sm.copyWith(color: c.textPrimary),
        decoration: _flatDecoration(
          hint: l.txNoteOptional,
          hintStyle: AppTypography.sm.copyWith(color: c.textHint),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// 来源下拉：选中后回传 id 与对应币种，便于联动金额币种字段。
class _SourceDropdown extends ConsumerWidget {
  const _SourceDropdown({required this.selected, required this.onPicked});

  final String? selected;
  final void Function(String? id, String? currency) onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allSourcesProvider);
    return async.when(
      data: (sources) {
        if (sources.isEmpty) {
          return _OutlinedBox(
            child: Text(
              l.txEmptySource,
              style: AppTypography.sm.copyWith(color: c.textMuted),
            ),
          );
        }
        return _OutlinedBox(
          height: _kFieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: selected,
              hint: Text(
                l.txSourcePlaceholder,
                style: AppTypography.sm.copyWith(color: c.textHint),
              ),
              icon:
                  Icon(LucideIcons.chevronDown, size: 16, color: c.textMuted),
              style: AppTypography.sm.copyWith(color: c.textPrimary),
              items: [
                for (final s in sources)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      '${_sourceDisplay(context, s)} · ${Currency.isSupported(s.currency) ? Currency.byCode(s.currency).symbol : s.currency}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) {
                  onPicked(null, null);
                  return;
                }
                final src = sources.firstWhere((s) => s.id == v);
                onPicked(v, src.currency);
              },
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
    );
  }
}

/// 表单底部固定操作条：取消 + 保存。
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.submitting,
    required this.onCancel,
    required this.onSave,
  });
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: submitting ? null : onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
                side: BorderSide(color: c.border),
                foregroundColor: c.textBody,
              ),
              child: Text(l.txCancel),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: FilledButton(
              onPressed: submitting ? null : onSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
                backgroundColor: c.action,
              ),
              child: Text(
                submitting ? '...' : l.txSave,
                style: AppTypography.sm.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 行内字段错误提示：`show=false` 时占位为零，避免布局抖动。
class _ErrorIfAny extends StatelessWidget {
  const _ErrorIfAny({required this.show, required this.message});
  final bool show;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x1),
      child: Text(message, style: AppTypography.xs.copyWith(color: c.expense)),
    );
  }
}

String _sourceDisplay(BuildContext context, Source s) {
  final localized = resolveDefaultName(AppL10n.of(context), s.nameKey);
  return localized ?? s.name;
}
