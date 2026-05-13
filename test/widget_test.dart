import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_harbor_app_local/app.dart';
import 'package:spend_harbor_app_local/shared/providers/preferences_provider.dart';

void main() {
  testWidgets('App boots and renders theme preview', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const SpendHarborApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Theme Preview'), findsOneWidget);
    expect(find.text('Typography'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
  });
}
