import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

/// 一项胶囊式分段选择器选项。
class PillSegment<T> {
  const PillSegment({required this.value, required this.label});
  final T value;
  final String label;
}

/// 多选项胶囊式分段（≥2 项）：外圈 borderSoft 边、单一选中色（默认 mintSoft）。
///
/// Stats 的 week/month/year、Budget 的 week/month/year 都走这个。
class PillSegmented<T> extends StatelessWidget {
  const PillSegmented({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    this.activeBg,
    this.activeText,
  });

  final T value;
  final List<PillSegment<T>> segments;
  final ValueChanged<T> onChanged;

  /// 选中态背景；缺省 `c.mintSoft`。
  final Color? activeBg;

  /// 选中态文字；缺省 `c.actionInk`。
  final Color? activeText;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bg = activeBg ?? c.mintSoft;
    final fg = activeText ?? c.actionInk;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: c.borderSoft),
        borderRadius: AppRadius.brFull,
      ),
      child: Row(
        children: [
          for (final seg in segments)
            Expanded(
              child: _Tile(
                label: seg.label,
                active: seg.value == value,
                activeBg: bg,
                activeText: fg,
                inactiveText: c.textMuted,
                onTap: () => onChanged(seg.value),
              ),
            ),
        ],
      ),
    );
  }
}

/// 二选项胶囊式切换：每个选项可有自己的选中色（如 Expense=red / Income=green）。
class PillToggle<T> extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.value,
    required this.first,
    required this.second,
    required this.onChanged,
  });

  final T value;
  final PillToggleOption<T> first;
  final PillToggleOption<T> second;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.borderSoft,
        borderRadius: AppRadius.brFull,
      ),
      child: Row(
        children: [
          for (final opt in [first, second])
            Expanded(
              child: _Tile(
                label: opt.label,
                active: opt.value == value,
                activeBg: opt.activeColor,
                activeText: Colors.white,
                inactiveText: c.textMuted,
                onTap: () => onChanged(opt.value),
              ),
            ),
        ],
      ),
    );
  }
}

class PillToggleOption<T> {
  const PillToggleOption({
    required this.value,
    required this.label,
    required this.activeColor,
  });
  final T value;
  final String label;
  final Color activeColor;
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.active,
    required this.activeBg,
    required this.activeText,
    required this.inactiveText,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color activeBg;
  final Color activeText;
  final Color inactiveText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brFull,
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: AppRadius.brFull,
          ),
          child: Text(
            label,
            style: AppTypography.sm.copyWith(
              fontWeight: AppTypography.weightSemibold,
              color: active ? activeText : inactiveText,
            ),
          ),
        ),
      ),
    );
  }
}
