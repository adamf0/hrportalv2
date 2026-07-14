import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrportalv2/main.dart';
import 'package:hrportalv2/state/app_state.dart';

void main() {
  testWidgets('HR Portal App SSO Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppState(),
        child: const HrPortalApp(),
      ),
    );

    // Verify that the login screen elements for SSO exist
    expect(find.text('HR Portal'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk dengan Unpak SSO'), findsOneWidget);
  });
}
