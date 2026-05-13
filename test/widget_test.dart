import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/app.dart';
import 'package:spend_harbor_app_local/data/database/app_database.dart';
import 'package:spend_harbor_app_local/data/database/app_database_provider.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

Future<List<Override>> _bootstrap({bool onboardingDone = false}) async {
  SharedPreferences.setMockInitialValues(
    onboardingDone ? {'onboarding.done': true} : {},
  );
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appDatabaseProvider.overrideWithValue(db),
  ];
}

void main() {
  testWidgets('未完成 Onboarding 时落到 onboarding 页', (tester) async {
    final overrides = await _bootstrap();
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const SpendHarborApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to SpendHarbor'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('已完成 Onboarding 时渲染主框架 + 底部 tabs', (tester) async {
    final overrides = await _bootstrap(onboardingDone: true);
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const SpendHarborApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
