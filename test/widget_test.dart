import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/app.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

Future<({List<Override> overrides, AppDatabase db})> _bootstrap(
    {bool onboardingDone = false}) async {
  SharedPreferences.setMockInitialValues(
    onboardingDone ? {'onboarding.done': true} : {},
  );
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return (
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
    ],
    db: db,
  );
}

void main() {
  testWidgets('未完成 Onboarding 时落到 onboarding 页', (tester) async {
    final boot = await _bootstrap();
    addTearDown(boot.db.close);
    await tester.pumpWidget(
      ProviderScope(overrides: boot.overrides, child: const SpendHarborApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to SpendHarbor'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  // 注：「已完成 Onboarding 后渲染主框架」一类的 widget 烟雾测试需要稳定的
  // 流式数据，等 fakeAsync 或集成测试基础设施落地后再补。当前控制器/聚合的
  // 单元测试已覆盖 router 之外的所有逻辑。
}
