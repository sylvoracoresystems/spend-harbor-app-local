import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/app.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

void main() {
  testWidgets('未完成 Onboarding 时落到 onboarding 页', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SpendHarborApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to SpendHarbor'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('已完成 Onboarding 时渲染主框架 + 底部 tabs', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding.done': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SpendHarborApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
