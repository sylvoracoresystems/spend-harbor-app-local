import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spend_harbor_app_local/app.dart';

void main() {
  testWidgets('App boots and shows placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SpendHarborApp()),
    );
    expect(find.text('SpendHarbor — scaffold ready'), findsOneWidget);
  });
}
