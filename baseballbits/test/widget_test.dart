import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baseballbits/main.dart';
import 'package:baseballbits/models/quotes_provider.dart';

void main() {
  testWidgets('Baseball Bits loads quote slider', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => QuotesProvider(),
        child: const BaseballBitsApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Baseball Bits'), findsOneWidget);
    expect(find.textContaining('Quote 1 of'), findsOneWidget);
  });
}
