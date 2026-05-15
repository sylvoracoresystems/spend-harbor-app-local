import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/transactions/application/transactions_list_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 通用年-月下拉按钮：点击弹出 picker 让用户选择年月。
class MonthDropdown extends StatelessWidget {
  const MonthDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final YearMonth value;
  final ValueChanged<YearMonth> onChanged;

  String _label(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'zh') {
      return '${value.year} 年 ${value.month} 月';
    }
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monthsEn[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      borderRadius: AppRadius.brXl,
      onTap: () async {
        final picked = await showDialog<YearMonth>(
          context: context,
          builder: (_) => _MonthPickerDialog(initial: value),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 14, color: c.textMuted),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                _label(context),
                style: AppTypography.sm.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: c.textPrimary,
                ),
              ),
            ),
            Icon(LucideIcons.chevronDown, size: 14, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});
  final YearMonth initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;

  List<String> _monthLabels(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'zh') {
      return List.generate(12, (i) => '${i + 1} 月');
    }
    return const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final labels = _monthLabels(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(LucideIcons.chevronLeft, size: 18),
                  color: c.textMuted,
                ),
                Text(
                  '$_year',
                  style: AppTypography.base.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: c.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(LucideIcons.chevronRight, size: 18),
                  color: c.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.x2,
              crossAxisSpacing: AppSpacing.x2,
              childAspectRatio: 1.8,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: labels[m - 1],
                    selected: _year == widget.initial.year &&
                        m == widget.initial.month,
                    onTap: () =>
                        Navigator.of(context).pop(YearMonth(_year, m)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.mintTint : Colors.transparent,
            border: Border.all(color: selected ? c.action : c.border),
            borderRadius: AppRadius.brLg,
          ),
          child: Text(
            label,
            style: AppTypography.sm.copyWith(
              color: selected ? c.action : c.textBody,
              fontWeight: selected
                  ? AppTypography.weightSemibold
                  : AppTypography.weightMedium,
            ),
          ),
        ),
      ),
    );
  }
}
