import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_harbor_app_local/features/settings/application/app_lock_controller.dart';

class _MemStorage implements LockStorage {
  String? _pin;
  bool _bio = false;
  @override
  Future<String?> readPin() async => _pin;
  @override
  Future<void> writePin(String? hash) async => _pin = hash;
  @override
  Future<bool> readBiometric() async => _bio;
  @override
  Future<void> writeBiometric(bool v) async => _bio = v;
}

Future<ProviderContainer> _container(_MemStorage storage) async {
  final c = ProviderContainer(overrides: [
    lockStorageProvider.overrideWithValue(storage),
  ]);
  addTearDown(c.dispose);
  // keep-alive subscription + 等 bootstrap 完成
  c.listen(appLockControllerProvider, (_, __) {});
  await Future<void>.delayed(const Duration(milliseconds: 30));
  return c;
}

void main() {
  group('hashPin', () {
    test('相同 PIN → 相同 hash', () {
      expect(hashPin('1234'), hashPin('1234'));
    });
    test('不同 PIN → 不同 hash', () {
      expect(hashPin('1234'), isNot(equals(hashPin('1235'))));
    });
    test('hash 不是明文（包含 PIN 子串说明有泄漏）', () {
      expect(hashPin('1234').contains('1234'), isFalse);
    });
  });

  test('启动时无 PIN → isEnabled=false, unlocked=true', () async {
    final storage = _MemStorage();
    final c = await _container(storage);
    // 等异步 bootstrap 完成
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final s = c.read(appLockControllerProvider);
    expect(s.isEnabled, isFalse);
    expect(s.unlocked, isTrue);
  });

  test('启动时已有 PIN → isEnabled=true, unlocked=false', () async {
    final storage = _MemStorage();
    await storage.writePin(hashPin('1234'));
    final c = await _container(storage);
    // 触发 bootstrap，再等异步完成
    c.read(appLockControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final s = c.read(appLockControllerProvider);
    expect(s.isEnabled, isTrue);
    expect(s.unlocked, isFalse);
  });

  test('setPin + verifyPin + clearLock', () async {
    final storage = _MemStorage();
    final c = await _container(storage);
    // 触发 bootstrap，再等异步完成
    c.read(appLockControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final ctrl = c.read(appLockControllerProvider.notifier);
    await ctrl.setPin('5678');
    expect(c.read(appLockControllerProvider).isEnabled, isTrue);
    expect(await ctrl.verifyPin('0000'), isFalse);
    expect(await ctrl.verifyPin('5678'), isTrue);
    expect(c.read(appLockControllerProvider).unlocked, isTrue);

    await ctrl.clearLock();
    final s = c.read(appLockControllerProvider);
    expect(s.isEnabled, isFalse);
    expect(s.biometricEnabled, isFalse);
  });

  test('setPin 长度过短抛错', () async {
    final storage = _MemStorage();
    final c = await _container(storage);
    // 触发 bootstrap，再等异步完成
    c.read(appLockControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(
      () => c.read(appLockControllerProvider.notifier).setPin('12'),
      throwsFormatException,
    );
  });

  test('setBiometric 仅在已启用 PIN 时生效', () async {
    final storage = _MemStorage();
    final c = await _container(storage);
    // 触发 bootstrap，再等异步完成
    c.read(appLockControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final ctrl = c.read(appLockControllerProvider.notifier);

    await ctrl.setBiometric(true); // 未启用 PIN → 无操作
    expect(c.read(appLockControllerProvider).biometricEnabled, isFalse);

    await ctrl.setPin('1234');
    await ctrl.setBiometric(true);
    expect(c.read(appLockControllerProvider).biometricEnabled, isTrue);
  });

  test('lock() 在启用时重置 unlocked', () async {
    final storage = _MemStorage();
    final c = await _container(storage);
    // 触发 bootstrap，再等异步完成
    c.read(appLockControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final ctrl = c.read(appLockControllerProvider.notifier);
    await ctrl.setPin('1234');
    expect(c.read(appLockControllerProvider).unlocked, isTrue);
    ctrl.lock();
    expect(c.read(appLockControllerProvider).unlocked, isFalse);
  });
}
