import 'package:flutter_test/flutter_test.dart';
import 'package:rdreporta/main.dart';

void main() {
  testWidgets('RDReporta app smoke test', (WidgetTester tester) async {
    // Build RDReporta app and trigger a frame.
    await tester.pumpWidget(const RdReportaApp());
    await tester.pump(const Duration(milliseconds: 200));

    // Verify that the title RDReporta is rendered in AppBar
    expect(find.text('RDReporta'), findsOneWidget);
  });
}
