import 'package:flutter_test/flutter_test.dart';

import 'package:syslogfui/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SyslogViewerApp());
    expect(find.text('SyslogFUI'), findsOneWidget);
  });
}
