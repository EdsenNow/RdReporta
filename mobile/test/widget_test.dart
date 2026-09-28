import 'package:flutter_test/flutter_test.dart';
import 'package:rdreporta/main.dart';

void main() {
  testWidgets('RDReporta app smoke test', (WidgetTester tester) async {
    // Build RDReporta app and trigger a frame.
    await tester.pumpWidget(const RdReportaApp());
    expect(find.text('RDReporta'), findsOneWidget);

    // Advance clock past the 900ms splash delay timer and complete navigation
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify navigation landed on LoginScreen or HomeScreen
    expect(find.byType(RdReportaApp), findsOneWidget);
  });
}
