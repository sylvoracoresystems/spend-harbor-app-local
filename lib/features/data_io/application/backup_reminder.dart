import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/preferences_provider.dart';

const _kLastBackupKey = 'backup.lastAt';

/// 超过这个天数算「该备份了」。
const int kBackupReminderThresholdDays = 30;

/// 备份状态。`lastBackupAt == null` 表示从未备份。
class BackupStatus {
  const BackupStatus({this.lastBackupAt, required this.now});

  final DateTime? lastBackupAt;
  final DateTime now;

  int? get daysSince {
    if (lastBackupAt == null) return null;
    return now.difference(lastBackupAt!).inDays;
  }

  /// 是否应提醒备份。
  bool get shouldRemind {
    if (lastBackupAt == null) return true;
    return daysSince! >= kBackupReminderThresholdDays;
  }
}

/// 当前备份状态。
final backupStatusProvider = Provider<BackupStatus>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final raw = prefs.getString(_kLastBackupKey);
  final last = raw == null ? null : DateTime.tryParse(raw);
  return BackupStatus(lastBackupAt: last, now: DateTime.now());
});

/// 在导出备份成功后调用：把 [when]（默认 now）写入 prefs。
Future<void> markBackupCompleted(
  SharedPreferences prefs, {
  DateTime? when,
}) async {
  await prefs.setString(
    _kLastBackupKey,
    (when ?? DateTime.now()).toIso8601String(),
  );
}
