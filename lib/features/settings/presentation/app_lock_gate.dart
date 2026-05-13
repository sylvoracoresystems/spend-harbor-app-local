import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
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
      if (ok) _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final lock = ref.watch(appLockControllerProvider);
    return Material(
      color: c.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.lock, size: 56, color: c.action),
              const SizedBox(height: AppSpacing.x4),
              Text(
                l.lockUnlockTitle,
                style: AppTypography.xl.copyWith(
                  color: c.actionInk,
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              TextField(
                controller: _ctrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l.lockEnterPin,
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.x4),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(l.lockEnterPin),
              ),
              if (lock.biometricEnabled) ...[
                const SizedBox(height: AppSpacing.x3),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.fingerprint),
                  onPressed: () => ref
                      .read(appLockControllerProvider.notifier)
                      .authenticateBiometric(l.lockBiometricReason),
                  label: Text(l.lockUseBiometric),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
