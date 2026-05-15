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
    final idx = segments.indexWhere((s) => s.value == value);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: c.borderSoft),
        borderRadius: AppRadius.brFull,
      ),
      child: _AnimatedPillBar(
        tileCount: segments.length,
        activeIndex: idx,
        activeBg: bg,
        builder: (i) => _AnimatedLabel(
          label: segments[i].label,
          active: i == idx,
          activeText: fg,
          inactiveText: c.textMuted,
          onTap: () => onChanged(segments[i].value),
        ),
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
    final opts = [first, second];
    final idx = value == first.value ? 0 : 1;
    final activeColor = opts[idx].activeColor;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.borderSoft,
        borderRadius: AppRadius.brFull,
      ),
      child: _AnimatedPillBar(
        tileCount: 2,
        activeIndex: idx,
        activeBg: activeColor,
        builder: (i) => _AnimatedLabel(
          label: opts[i].label,
          active: i == idx,
          activeText: Colors.white,
          inactiveText: c.textMuted,
          onTap: () => onChanged(opts[i].value),
        ),
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

/// 滑块底座：一个 AnimatedPositioned 的高亮在 N 个等宽 tile 之间滑动；
/// 上层覆盖 N 个透明 tile 接收点击。
class _AnimatedPillBar extends StatelessWidget {
  const _AnimatedPillBar({
    required this.tileCount,
    required this.activeIndex,
    required this.activeBg,
    required this.builder,
  });
  final int tileCount;
  final int activeIndex;
  final Color activeBg;
  final Widget Function(int index) builder;

  static const Duration _kDuration = Duration(milliseconds: 220);
  static const Curve _kCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        final tileW = cons.maxWidth / tileCount;
        return SizedBox(
          height: 36,
          child: Stack(
            children: [
              if (activeIndex >= 0)
                AnimatedPositioned(
                  duration: _kDuration,
                  curve: _kCurve,
                  left: activeIndex * tileW,
                  top: 0,
                  bottom: 0,
                  width: tileW,
                  child: AnimatedContainer(
                    duration: _kDuration,
                    curve: _kCurve,
                    decoration: BoxDecoration(
                      color: activeBg,
                      borderRadius: AppRadius.brFull,
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < tileCount; i++)
                    Expanded(child: builder(i)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedLabel extends StatelessWidget {
  const _AnimatedLabel({
    required this.label,
    required this.active,
    required this.activeText,
    required this.inactiveText,
    required this.onTap,
  });
  final String label;
  final bool active;
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
          child: AnimatedDefaultTextStyle(
            duration: _AnimatedPillBar._kDuration,
            curve: _AnimatedPillBar._kCurve,
            style: AppTypography.sm.copyWith(
              fontWeight: AppTypography.weightSemibold,
              color: active ? activeText : inactiveText,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
