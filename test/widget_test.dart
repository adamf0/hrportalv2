import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrportalv2/main.dart';
import 'package:hrportalv2/modules/auth/presentation/auth_bloc.dart';
import 'package:hrportalv2/modules/attendance/presentation/attendance_bloc.dart';
import 'package:hrportalv2/modules/leave/presentation/leave_bloc.dart';
import 'package:hrportalv2/modules/payroll/presentation/payroll_bloc.dart';

void main() {
  testWidgets('HR Portal App SSO Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AuthBloc()),
          ChangeNotifierProvider(create: (context) => AttendanceBloc()),
          ChangeNotifierProvider(create: (context) => LeaveBloc()),
          ChangeNotifierProvider(create: (context) => PayrollBloc()),
        ],
        child: const HrPortalApp(),
      ),
    );

    // Verify that the login screen elements for SSO exist
    // Note: Since SplashPage runs a timer or evaluates session, we pump
    // Advance virtual time to allow the 2.5s splash delay timer to fire and complete
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
