part of '../transaction_form.dart';

class _AmountAndCurrencyRow extends StatelessWidget {
  const _AmountAndCurrencyRow({
    required this.amountCtrl,
    required this.currency,
    required this.onAmount,
    required this.onCurrency,
  });

  final TextEditingController amountCtrl;
  final String? currency;
  final ValueChanged<String> onAmount;
  final ValueChanged<String> onCurrency;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = AppL10n.of(context);
    final amountStyle = AppTypography.lg.copyWith(
      fontWeight: AppTypography.weightSemibold,
      fontFeatures: AppTypography.monoFeatures,
      color: c.textPrimary,
    );
    return Row(
      children: [
        Expanded(
          child: _OutlinedBox(
            height: _kFieldHeight,
            child: TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: amountStyle,
              decoration: _flatDecoration(
                hint: l.txAmountPlaceholder,
                hintStyle: amountStyle.copyWith(color: c.textHint),
              ),
              onChanged: onAmount,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        SizedBox(
          width: 120,
          child: _OutlinedBox(
            height: _kFieldHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x3,
              vertical: 0,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: currency,
                isDense: true,
                icon: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: c.textMuted,
                ),
                style: AppTypography.sm.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: c.textPrimary,
                ),
                items: [
                  for (final cur in Currency.all)
                    DropdownMenuItem(
                      value: cur.code,
                      child: Text('${cur.symbol} - ${cur.code}'),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) onCurrency(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlinedBox extends StatelessWidget {
  const _OutlinedBox({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.x3,
      vertical: AppSpacing.x2,
    ),
    this.height,
  });
  final Widget child;
  final EdgeInsets padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: height,
      padding: padding,
      alignment: height != null ? Alignment.centerLeft : null,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: AppRadius.brXl,
      ),
      child: child,
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.value, required this.onPicked});
  final DateTime value;
  final ValueChanged<DateTime?> onPicked;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);
    final valueD = DateTime(value.year, value.month, value.day);
    final yesterday = todayD.subtract(const Duration(days: 1));
    final isYesterday = valueD == yesterday;
    final quickLabel = isYesterday ? l.dayToday : l.dayYesterday;
    final quickTarget = isYesterday ? todayD : yesterday;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: AppRadius.brXl,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (picked != null) onPicked(picked);
            },
            child: _OutlinedBox(
              height: _kFieldHeight,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${value.year.toString().padLeft(4, '0')}/'
                      '${value.month.toString().padLeft(2, '0')}/'
                      '${value.day.toString().padLeft(2, '0')}',
                      style: AppTypography.sm.copyWith(color: c.textPrimary),
                    ),
                  ),
                  Icon(LucideIcons.calendar, size: 16, color: c.textMuted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        SizedBox(
          width: 120,
          child: InkWell(
            borderRadius: AppRadius.brXl,
            onTap: () => onPicked(quickTarget),
            child: _OutlinedBox(
              height: _kFieldHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
              child: Center(
                child: Text(
                  quickLabel,
                  style: AppTypography.sm.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: c.textBody,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
