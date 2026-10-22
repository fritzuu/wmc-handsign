import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/main.dart';

void main() {
  testWidgets('WMC Vertical Handover app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app bar and home dashboard render.
    expect(find.text('WMC Simulator'), findsOneWidget);
    expect(find.text('Menu Utama'), findsOneWidget);
  });
}

