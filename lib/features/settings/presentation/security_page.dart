import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/app_lock_controller.dart';

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final state = ref.watch(appLockControllerProvider);
    final ctrl = ref.read(appLockControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.lockTitle)),
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
    final l = AppL10n.of(context);
    final p1 = TextEditingController();
    final p2 = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(change ? l.lockChangePin : l.lockSetPin),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: p1,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.lockEnterPin),
                ),
                TextField(
                  controller: p2,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.lockConfirmPin,
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.txCancel),
              ),
              FilledButton(
                onPressed: () {
                  if (p1.text.length < 4) {
                    setState(() => error = l.lockTooShort);
                    return;
                  }
                  if (p1.text != p2.text) {
                    setState(() => error = l.lockMismatch);
                    return;
                  }
                  Navigator.of(ctx).pop(true);
                },
                child: Text(l.txSave),
              ),
            ],
          );
        });
      },
    );
    p2.dispose();
    if (ok == true) {
      try {
        await ctrl.setPin(p1.text);
      } finally {
        p1.dispose();
      }
    } else {
      p1.dispose();
    }
  }
}
