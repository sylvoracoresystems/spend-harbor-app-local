import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// 表单 / 设置页里的小标题（灰色 xs medium），统一替代各页内联的 _SectionLabel。
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

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
