import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/features/data_io/application/backup_reminder.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

void main() {
  group('BackupStatus', () {
    test('从未备份 → shouldRemind=true, daysSince=null', () {
      final s = BackupStatus(now: DateTime(2026, 5, 13));
      expect(s.lastBackupAt, isNull);
      expect(s.daysSince, isNull);
      expect(s.shouldRemind, isTrue);
    });
    test('刚备份 → daysSince=0, shouldRemind=false', () {
      final now = DateTime(2026, 5, 13);
      final s = BackupStatus(lastBackupAt: now, now: now);
      expect(s.daysSince, 0);
      expect(s.shouldRemind, isFalse);
    });
    test('30 天前 → shouldRemind=true', () {
      final now = DateTime(2026, 5, 13);
      final s = BackupStatus(
        lastBackupAt: now.subtract(const Duration(days: 30)),
        now: now,
      );
      expect(s.daysSince, 30);
      expect(s.shouldRemind, isTrue);
    });
    test('29 天前 → shouldRemind=false', () {
      final now = DateTime(2026, 5, 13);
      final s = BackupStatus(
        lastBackupAt: now.subtract(const Duration(days: 29)),
        now: now,
      );
      expect(s.shouldRemind, isFalse);
    });
  });

  test('markBackupCompleted 写 ISO 字符串到 prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final when = DateTime(2026, 5, 13, 12, 0);
    await markBackupCompleted(prefs, when: when);
    expect(prefs.getString('backup.lastAt'), when.toIso8601String());
  });

  test('backupStatusProvider 读取 prefs', () async {
    final when = DateTime.now().subtract(const Duration(days: 5));
    SharedPreferences.setMockInitialValues({
      'backup.lastAt': when.toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    final status = container.read(backupStatusProvider);
    expect(status.lastBackupAt, when);
    expect(status.daysSince, anyOf(equals(4), equals(5)));
    expect(status.shouldRemind, isFalse);
  });
}
