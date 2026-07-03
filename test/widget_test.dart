import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summarizit/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SummarizItApp(prefs: prefs));
    expect(find.text('SummarizIt'), findsOneWidget);
  });
}
