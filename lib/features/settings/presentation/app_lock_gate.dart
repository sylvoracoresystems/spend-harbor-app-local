import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../application/app_lock_controller.dart';

/// 包住整个 [child]：当锁定时覆盖一层解锁界面。
/// 同时监听 App 生命周期：进入后台 → 重新锁定。
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(appLockControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockControllerProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (lock.isGated)
          const Positioned.fill(
            child: _LockScreen(),
          ),
      ],
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();
  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (_biometricAttempted || !mounted) return;
    _biometricAttempted = true;
    final lock = ref.read(appLockControllerProvider);
    if (!lock.biometricEnabled) return;
    final l = AppL10n.of(context);
    await ref
        .read(appLockControllerProvider.notifier)
        .authenticateBiometric(l.lockBiometricReason);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppL10n.of(context);
    setState(() => _busy = true);
    final ok = await ref
        .read(appLockControllerProvider.notifier)
        .verifyPin(_ctrl.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = ok ? null : l.lockWrong;
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final lock = ref.watch(appLockControllerProvider);
    final hasError = _error != null;

    return Material(
      color: c.bgMint,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 头部图标
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: AppRadius.brXxl,
                      border: Border.all(color: c.mintTint, width: 1),
                    ),
                    child: Icon(
                      LucideIcons.lock,
                      size: 32,
                      color: c.action,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                // 标题
                Text(
                  l.lockUnlockTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.xl.copyWith(
                    color: c.actionInk,
                    fontWeight: AppTypography.weightSemibold,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                // 副标题
                Text(
                  l.lockEnterPin,
                  textAlign: TextAlign.center,
                  style: AppTypography.sm.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: AppSpacing.x8),
                // PIN 输入
                Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: AppRadius.brLg,
                    border: Border.all(
                      color: hasError ? c.expense : c.borderSoft,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x4,
                  ),
                  child: TextField(
                    controller: _ctrl,
                    obscureText: true,
                    obscuringCharacter: '●',
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    enabled: !_busy,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _submit(),
                    style: AppTypography.lg.merge(AppTypography.mono).copyWith(
                          color: c.actionInk,
                          fontWeight: AppTypography.weightSemibold,
                          letterSpacing: 6,
                        ),
                    decoration: InputDecoration(
                      hintText: l.lockEnterPin,
                      hintStyle: AppTypography.base.copyWith(
                        color: c.textHint,
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.x4,
                      ),
                    ),
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.x2,
                      left: AppSpacing.x2,
                    ),
                    child: Text(
                      _error!,
                      style: AppTypography.xs.copyWith(color: c.expense),
                    ),
                  ),
                const SizedBox(height: AppSpacing.x6),
                // 主按钮
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.action,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.brLg,
                      ),
                    ),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l.lockUnlockTitle,
                            style: AppTypography.base.copyWith(
                              fontWeight: AppTypography.weightSemibold,
                            ),
                          ),
                  ),
                ),
                if (lock.biometricEnabled) ...[
                  const SizedBox(height: AppSpacing.x3),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: c.action,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.x3,
                      ),
                    ),
                    icon: const Icon(LucideIcons.fingerprint, size: 20),
                    onPressed: _busy
                        ? null
                        : () => ref
                            .read(appLockControllerProvider.notifier)
                            .authenticateBiometric(l.lockBiometricReason),
                    label: Text(
                      l.lockUseBiometric,
                      style: AppTypography.sm.copyWith(
                        fontWeight: AppTypography.weightMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
