import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../transactions/application/transactions_list_controller.dart';
import '../application/dashboard_filter_provider.dart';

/// Dashboard 顶部过滤条：① 月份导航  ② 货币 / 来源下拉。
class DashboardFilterBar extends ConsumerWidget {
  const DashboardFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ym = ref.watch(currentMonthProvider);
    final filter = ref.watch(dashboardFilterProvider);
    final sourcesAsync = ref.watch(allSourcesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSoft)),
      ),
      child: Column(
        children: [
          _MonthNav(ym: ym, l: l, c: c, ref: ref),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: _CurrencyDropdown(
                  value: filter.currency,
                  onChanged: (v) =>
                      ref.read(dashboardFilterProvider.notifier).setCurrency(v),
                  label: l.dashFilterCurrency,
                  allLabel: l.dashFilterAll,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: _SourceDropdown(
                  value: filter.sourceId,
                  onChanged: (v) =>
                      ref.read(dashboardFilterProvider.notifier).setSource(v),
                  label: l.dashFilterSource,
                  allLabel: l.dashFilterAll,
                  sources: sourcesAsync.maybeWhen(
                    data: (rows) => rows,
                    orElse: () => const <Source>[],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.ym,
    required this.l,
    required this.c,
    required this.ref,
  });
  final YearMonth ym;
  final AppL10n l;
  final AppColors c;
  final WidgetRef ref;

  String _label(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'zh') {
      return '${ym.year} 年 ${ym.month} 月';
    }
    // 英文：May 2026
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monthsEn[ym.month - 1]} ${ym.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavBtn(
            icon: LucideIcons.chevronLeft,
            tooltip: l.dashPrevMonth,
            onTap: () => ref.read(currentMonthProvider.notifier).prev(),
            c: c,
          ),
          const SizedBox(width: AppSpacing.x3),
          Text(
            _label(context),
            style: AppTypography.base.copyWith(
              fontWeight: AppTypography.weightSemibold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          _NavBtn(
            icon: LucideIcons.chevronRight,
            tooltip: l.dashNextMonth,
            onTap: () => ref.read(currentMonthProvider.notifier).next(),
            c: c,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.c,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: c.textMuted),
        ),
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.allLabel,
  });
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return _FilterPill(
      icon: LucideIcons.dollarSign,
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          isDense: true,
          value: value,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(allLabel),
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

class _SourceDropdown extends StatelessWidget {
  const _SourceDropdown({
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
    // 若当前选中的 id 不在 sources 列表里（来源被删？），回退 null 防止 dropdown crash。
    final safe = value != null && sources.any((s) => s.id == value)
        ? value
        : null;
    return _FilterPill(
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

/// 单行紧凑外框：左 icon + 内置 dropdown。高度 ~36pt。
class _FilterPill extends StatelessWidget {
  const _FilterPill({
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
        color: c.surfacePress,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: c.borderSoft),
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
