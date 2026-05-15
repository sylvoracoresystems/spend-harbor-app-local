import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/database/app_database.dart';
import '../../domain/value_objects/currency.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 过滤栏统一外框：左 icon + 内置控件。高度 36pt，brXl + surface/border。
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
  });
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.textMuted),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: DefaultTextStyle(
              style: AppTypography.sm.copyWith(color: c.textPrimary),
              child: Semantics(label: label, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// 货币过滤下拉。[allLabel] = null 表示不允许「全部」选项（必选场景）。
class CurrencyFilterDropdown extends StatelessWidget {
  const CurrencyFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.allLabel,
  });
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    return FilterPill(
      icon: LucideIcons.dollarSign,
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          isDense: true,
          value: value,
          items: [
            if (allLabel != null)
              DropdownMenuItem<String?>(
                value: null,
                child: Text(allLabel!),
              ),
            for (final ccy in Currency.all)
              DropdownMenuItem<String?>(
                value: ccy.code,
                child: Text(ccy.code),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// 来源过滤下拉。当 [value] 不在 [sources] 中（来源被删）回退 null 防 crash。
class SourceFilterDropdown extends StatelessWidget {
  const SourceFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.allLabel,
    required this.sources,
  });
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String allLabel;
  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    final safe = value != null && sources.any((s) => s.id == value)
        ? value
        : null;
    return FilterPill(
      icon: LucideIcons.wallet,
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          isDense: true,
          value: safe,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(allLabel),
            ),
            for (final s in sources)
              DropdownMenuItem<String?>(
                value: s.id,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
