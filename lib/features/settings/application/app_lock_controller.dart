import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const _kPinKey = 'lock.pinHash';
const _kBiometricKey = 'lock.biometricEnabled';

/// 应用锁公开状态。
class AppLockState {
  const AppLockState({
    required this.isEnabled,
    required this.biometricEnabled,
    required this.unlocked,
  });

  final bool isEnabled;
  final bool biometricEnabled;
  final bool unlocked;

  AppLockState copyWith({
    bool? isEnabled,
    bool? biometricEnabled,
    bool? unlocked,
  }) =>
      AppLockState(
        isEnabled: isEnabled ?? this.isEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        unlocked: unlocked ?? this.unlocked,
      );

  /// 需要展示 LockGate 的条件。
  bool get isGated => isEnabled && !unlocked;
}

/// PIN 哈希函数（纯）：sha256(salt + pin)。`salt` 固定但不机密 —— hash 主要防止把
/// 明文 PIN 写到磁盘；真正的攻防由 secure_storage 平台层保证（Keychain / EncryptedSP）。
const _kSalt = 'spend-harbor-local.v1';

String hashPin(String pin) {
  final bytes = utf8.encode('$_kSalt:$pin');
  return sha256.convert(bytes).toString();
}

/// secure_storage 抽象 —— 测试时可注入内存实现。
abstract class LockStorage {
  Future<String?> readPin();
  Future<void> writePin(String? hash);
  Future<bool> readBiometric();
  Future<void> writeBiometric(bool v);
}

/// 默认 LockStorage 实现：基于 flutter_secure_storage 的 keychain/keystore。
class _SecureLockStorage implements LockStorage {
  _SecureLockStorage(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readPin() => _storage.read(key: _kPinKey);

  @override
  Future<void> writePin(String? hash) async {
    if (hash == null) {
      await _storage.delete(key: _kPinKey);
    } else {
      await _storage.write(key: _kPinKey, value: hash);
    }
  }

  @override
  Future<bool> readBiometric() async {
    return (await _storage.read(key: _kBiometricKey)) == 'true';
  }

  @override
  Future<void> writeBiometric(bool v) =>
      _storage.write(key: _kBiometricKey, value: v ? 'true' : 'false');
}

/// 测试场景下可覆盖：内存实现。
final lockStorageProvider = Provider<LockStorage>(
  (ref) => _SecureLockStorage(const FlutterSecureStorage()),
);

/// 生物识别本地接口；测试可覆盖。
final localAuthProvider =
    Provider<LocalAuthentication>((ref) => LocalAuthentication());

/// 管理 app 启动锁：PIN 设置/校验、生物识别开关、未解锁态拦截。
class AppLockController extends StateNotifier<AppLockState> {
  AppLockController(this._ref)
      : super(const AppLockState(
          isEnabled: false,
          biometricEnabled: false,
          unlocked: true,
        )) {
    _bootstrap();
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    final storage = _ref.read(lockStorageProvider);
    final hash = await storage.readPin();
    final bio = await storage.readBiometric();
    final hasPin = hash != null && hash.isNotEmpty;
    state = AppLockState(
      isEnabled: hasPin,
      biometricEnabled: hasPin && bio,
      // 启动时若启用，则进入锁定态
      unlocked: !hasPin,
    );
  }

  /// 设置/修改 PIN：写入 hash，开启锁。
  Future<void> setPin(String pin) async {
    if (pin.length < 4) throw const FormatException('PIN too short');
    await _ref.read(lockStorageProvider).writePin(hashPin(pin));
    state = state.copyWith(isEnabled: true, unlocked: true);
  }

  /// 关闭应用锁：清空 PIN + 生物识别。
  Future<void> clearLock() async {
    final storage = _ref.read(lockStorageProvider);
    await storage.writePin(null);
    await storage.writeBiometric(false);
    state = const AppLockState(
      isEnabled: false,
      biometricEnabled: false,
      unlocked: true,
    );
  }

  Future<void> setBiometric(bool enabled) async {
    if (!state.isEnabled) return;
    await _ref.read(lockStorageProvider).writeBiometric(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _ref.read(lockStorageProvider).readPin();
    if (stored == null) return false;
    final ok = stored == hashPin(pin);
    if (ok) state = state.copyWith(unlocked: true);
    return ok;
  }

  /// 调起系统生物识别；成功则解锁。
  Future<bool> authenticateBiometric(String reason) async {
    if (!state.biometricEnabled) return false;
    try {
      final ok = await _ref.read(localAuthProvider).authenticate(
            localizedReason: reason,
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          );
      if (ok) state = state.copyWith(unlocked: true);
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// App 切到后台 → 重新锁定。
  void lock() {
    if (state.isEnabled) state = state.copyWith(unlocked: false);
  }
}

final appLockControllerProvider =
    StateNotifierProvider<AppLockController, AppLockState>(
  (ref) => AppLockController(ref),
);
