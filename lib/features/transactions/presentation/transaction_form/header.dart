part of '../transaction_form.dart';

/// 表单顶栏：返回 + 标题 + （可选）删除/设置按钮。
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.showDelete,
    required this.onBack,
    this.onDelete,
    this.onSettings,
  });

  final String title;
  final bool showDelete;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSoft)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(LucideIcons.chevronLeft),
            color: c.textPrimary,
            iconSize: 22,
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.base.copyWith(
                fontWeight: AppTypography.weightSemibold,
                color: c.textPrimary,
              ),
            ),
          ),
          if (showDelete)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(LucideIcons.trash2),
              color: c.expense,
              iconSize: 20,
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSettings,
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.mintTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.settings, size: 18, color: c.action),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
