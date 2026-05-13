import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spend_harbor_app_local/app.dart';

void main() {
  testWidgets('App boots and renders theme preview', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SpendHarborApp()),
    );
    await tester.pump();
    expect(find.text('Theme Preview'), findsOneWidget);
    expect(find.text('Typography'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
  });
}
