import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/app_lock_controller.dart';

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final state = ref.watch(appLockControllerProvider);
    final ctrl = ref.read(appLockControllerProvider.notifier);

    return SubPageScaffold(
      title: l.lockTitle,
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l.lockEnableToggle),
            value: state.isEnabled,
            onChanged: (v) async {
              if (v) {
                await _openSetPin(context, ctrl);
              } else {
                await ctrl.clearLock();
              }
            },
          ),
          if (state.isEnabled)
            ListTile(
              title: Text(l.lockChangePin),
              onTap: () => _openSetPin(context, ctrl, change: true),
            ),
          if (state.isEnabled)
            SwitchListTile(
              title: Text(l.lockBiometricToggle),
              value: state.biometricEnabled,
              onChanged: (v) => ctrl.setBiometric(v),
            ),
        ],
      ),
    );
  }

  Future<void> _openSetPin(
    BuildContext context,
    AppLockController ctrl, {
    bool change = false,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _SetPinDialog(change: change),
    );
    if (result != null) {
      await ctrl.setPin(result);
    }
  }
}

class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog({required this.change});
  final bool change;

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();
  String? _error;

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    _f1.dispose();
    _f2.dispose();
    super.dispose();
  }

  void _submit() {
    final l = AppL10n.of(context);
    if (_p1.text.length < 4) {
      setState(() => _error = l.lockTooShort);
      return;
    }
    if (_p1.text != _p2.text) {
      setState(() => _error = l.lockMismatch);
      return;
    }
    Navigator.of(context).pop(_p1.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;

    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brXxl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x6,
          AppSpacing.x6,
          AppSpacing.x6,
          AppSpacing.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 头部图标
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.mintSoft,
                  borderRadius: AppRadius.brXl,
                ),
                child: Icon(
                  LucideIcons.shieldCheck,
                  size: 28,
                  color: c.action,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            // 标题
            Text(
              widget.change ? l.lockChangePin : l.lockSetPin,
              textAlign: TextAlign.center,
              style: AppTypography.lg.copyWith(
                color: c.actionInk,
                fontWeight: AppTypography.weightSemibold,
              ),
            ),
            const SizedBox(height: AppSpacing.x1),
            // 副标题
            Text(
              l.lockTooShort,
              textAlign: TextAlign.center,
              style: AppTypography.sm.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.x6),
            // 第一个 PIN 输入
            _PinField(
              controller: _p1,
              focusNode: _f1,
              hint: l.lockEnterPin,
              autofocus: true,
              onSubmitted: (_) => _f2.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.x3),
            // 第二个 PIN 输入
            _PinField(
              controller: _p2,
              focusNode: _f2,
              hint: l.lockConfirmPin,
              error: _error,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.x6),
            // 主按钮
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.action,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                ),
                onPressed: _submit,
                child: Text(
                  l.txSave,
                  style: AppTypography.base.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x1),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l.txCancel,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.error,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String? error;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.bgMint,
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: hasError ? c.expense : c.borderSoft,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            obscureText: true,
            obscuringCharacter: '●',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            textAlign: TextAlign.center,
            onSubmitted: onSubmitted,
            style: AppTypography.lg.merge(AppTypography.mono).copyWith(
                  color: c.actionInk,
                  fontWeight: AppTypography.weightSemibold,
                  letterSpacing: 6,
                ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.base.copyWith(
                color: c.textHint,
                letterSpacing: 0,
              ),
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.x4),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.x1,
              left: AppSpacing.x2,
            ),
            child: Text(
              error!,
              style: AppTypography.xs.copyWith(color: c.expense),
            ),
          ),
      ],
    );
  }
}
