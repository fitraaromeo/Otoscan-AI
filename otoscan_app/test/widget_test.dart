import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:otoscan_app/main.dart';
import 'package:otoscan_app/state/app_state.dart';

void main() {
  testWidgets('OtoScan app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const OtoScanApp(),
      ),
    );

    // Verify title and app name render
    expect(find.text('OtoScan AI'), findsOneWidget);
  });
}
