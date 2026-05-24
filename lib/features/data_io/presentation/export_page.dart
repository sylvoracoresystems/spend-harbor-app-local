import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/pill_segmented.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../transactions/application/transactions_list_controller.dart';
import '../application/export_controller.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _txBusy = false;
  bool _taxBusy = false;
  ExportFormat _format = ExportFormat.xlsx;
  ExportScope _scope = ExportScope.currentMonth;
  // 自定义日期段（仅在 _scope == range 时使用）
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _rangeEnd = DateTime.now();

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool get _rangeValid => !_rangeEnd.isBefore(_rangeStart);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ym = ref.watch(currentMonthProvider);
    final monthAsync = ref.watch(transactionsOfMonthProvider);
    final monthEmpty = (monthAsync.valueOrNull ?? const []).isEmpty;

    return SubPageScaffold(
      title: l.exportTitle,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: [
          _SectionCard(
            title: l.exportSectionTransactions,
            children: [
              SectionLabel(l.exportFormatLabel),
              const SizedBox(height: AppSpacing.x2),
              PillSegmented<ExportFormat>(
                value: _format,
                segments: [
                  PillSegment(
                    value: ExportFormat.xlsx,
                    label: l.exportFormatXlsx,
                  ),
                  PillSegment(
                    value: ExportFormat.csv,
                    label: l.exportFormatCsv,
                  ),
                ],
                onChanged: (v) => setState(() => _format = v),
              ),
              const SizedBox(height: AppSpacing.x4),
              SectionLabel(l.exportScopeLabel),
              const SizedBox(height: AppSpacing.x2),
              PillSegmented<ExportScope>(
                value: _scope,
                segments: [
                  PillSegment(
                    value: ExportScope.currentMonth,
                    label: l.exportScopeMonth(ym.key),
                  ),
                  PillSegment(
                    value: ExportScope.range,
                    label: l.exportScopeRange,
                  ),
                  PillSegment(
                    value: ExportScope.all,
                    label: l.exportScopeAll,
                  ),
                ],
                onChanged: (v) => setState(() => _scope = v),
              ),
              if (_scope == ExportScope.range) ...[
                const SizedBox(height: AppSpacing.x3),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: l.exportRangeStart,
                        value: _rangeStart,
                        onPick: (d) => setState(() => _rangeStart = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: _DateField(
                        label: l.exportRangeEnd,
                        value: _rangeEnd,
                        onPick: (d) => setState(() => _rangeEnd = d),
                      ),
                    ),
                  ],
                ),
                if (!_rangeValid) ...[
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    l.exportRangeInvalid,
                    style: AppTypography.xs.copyWith(color: c.expense),
                  ),
                ],
              ],
              if (_scope == ExportScope.currentMonth && monthEmpty) ...[
                const SizedBox(height: AppSpacing.x3),
                Text(
                  l.exportEmptyMonth,
                  style: AppTypography.xs.copyWith(color: c.textMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.x4),
              FilledButton.icon(
                icon: _txBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.download),
                label: Text(l.exportButton),
                onPressed: _txButtonEnabled(monthEmpty) ? _runTxExport : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          _SectionCard(
            title: l.exportSectionTaxonomy,
            children: [
              Text(
                l.exportTaxonomyHint,
                style: AppTypography.sm.copyWith(color: c.textBody),
              ),
              const SizedBox(height: AppSpacing.x4),
              FilledButton.icon(
                icon: _taxBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.download),
                label: Text(l.exportTaxonomyButton),
                onPressed: _taxBusy ? null : _runTaxExport,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _txButtonEnabled(bool monthEmpty) {
    if (_txBusy) return false;
    if (_scope == ExportScope.currentMonth && monthEmpty) return false;
    if (_scope == ExportScope.range && !_rangeValid) return false;
    return true;
  }

  Future<void> _runTxExport() async {
    setState(() => _txBusy = true);
    try {
      final l = AppL10n.of(context);
      await exportTransactions(
        ref: ref,
        l: l,
        scope: _scope,
        format: _format,
        rangeStart: _scope == ExportScope.range ? _fmtDate(_rangeStart) : null,
        rangeEnd: _scope == ExportScope.range ? _fmtDate(_rangeEnd) : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.exportDone)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _txBusy = false);
    }
  }

  Future<void> _runTaxExport() async {
    setState(() => _taxBusy = true);
    try {
      final l = AppL10n.of(context);
      await exportTaxonomy(ref: ref, l: l);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.exportDone)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _taxBusy = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.base.copyWith(
              color: c.actionInk,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          ...children,
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.brLg,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}',
          style: AppTypography.sm,
        ),
      ),
    );
  }
}
