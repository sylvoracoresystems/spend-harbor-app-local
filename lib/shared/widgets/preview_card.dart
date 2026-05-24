import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 编辑表单顶部的"实时预览卡片"：左侧圆形 icon + 右侧名称（或占位灰字）。
///
/// 替代 category_edit / tag_edit / source_edit 各自内联的 _PreviewCard。
/// 当 [icon] 为 null 时只渲染纯色圆（Tag 场景历史上没 icon，但本组件默认仍取
/// `LucideIcons.tag` 由调用方传入；这里不写死默认值以保持 widget 层无业务耦合）。
class PreviewCard extends StatelessWidget {
  const PreviewCard({
    super.key,
    required this.color,
    required this.name,
    required this.placeholder,
    this.icon,
  });

  final IconData? icon;
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
            child: icon == null
                ? null
                : Icon(icon, size: 28, color: Colors.white),
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
