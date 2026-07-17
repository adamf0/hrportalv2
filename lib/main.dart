import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Core & Mediator
import 'core/mediator/mediator.dart';
import 'core/api_client.dart';
import 'core/app_theme.dart';

// Auth Module
import 'modules/auth/domain/auth.dart';
import 'modules/auth/domain/i_auth_repository.dart';
import 'modules/auth/application/login/login_command.dart';
import 'modules/auth/application/login/login_command_handler.dart';
import 'modules/auth/application/logout/logout_command.dart';
import 'modules/auth/application/logout/logout_command_handler.dart';
import 'modules/auth/application/check_token/check_token_query.dart';
import 'modules/auth/application/check_token/check_token_query_handler.dart';
import 'modules/auth/application/permissions/check_permissions_query.dart';
import 'modules/auth/application/permissions/check_permissions_query_handler.dart';
import 'modules/auth/application/permissions/request_permissions_command.dart';
import 'modules/auth/application/permissions/request_permissions_command_handler.dart';
import 'modules/auth/infrastructure/auth_repository.dart';
import 'modules/auth/presentation/auth_bloc.dart';
import 'modules/auth/presentation/components/pages/splash_page.dart';
import 'modules/auth/presentation/components/pages/login_page.dart';

// Attendance Module
import 'modules/attendance/domain/i_attendance_repository.dart';
import 'modules/attendance/domain/attendance.dart';
import 'modules/attendance/application/check_in/check_in_command.dart';
import 'modules/attendance/application/check_in/check_in_command_handler.dart';
import 'modules/attendance/application/check_out/check_out_command.dart';
import 'modules/attendance/application/check_out/check_out_command_handler.dart';
import 'modules/attendance/application/get_history/get_history_query.dart';
import 'modules/attendance/application/get_history/get_history_query_handler.dart';
import 'modules/attendance/infrastructure/attendance_repository.dart';
import 'modules/attendance/presentation/attendance_bloc.dart';

// Leave Module
import 'modules/leave/domain/leave.dart';
import 'modules/leave/domain/i_leave_repository.dart';
import 'modules/leave/application/submit_leave/submit_leave_command.dart';
import 'modules/leave/application/submit_leave/submit_leave_command_handler.dart';
import 'modules/leave/application/get_leaves/get_leaves_query.dart';
import 'modules/leave/application/get_leaves/get_leaves_query_handler.dart';
import 'modules/leave/application/get_supervisors/get_supervisors_query.dart';
import 'modules/leave/application/get_supervisors/get_supervisors_query_handler.dart';
import 'modules/leave/infrastructure/leave_repository.dart';
import 'modules/leave/presentation/leave_bloc.dart';

// Payroll Module
import 'modules/payroll/domain/payroll.dart';
import 'modules/payroll/domain/i_payroll_repository.dart';
import 'modules/payroll/application/get_salary_slip/get_salary_slip_query.dart';
import 'modules/payroll/application/get_salary_slip/get_salary_slip_query_handler.dart';
import 'modules/payroll/infrastructure/payroll_repository.dart';
import 'modules/payroll/presentation/payroll_bloc.dart';

// Navigation Shell
import 'pages/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure custom Mediator and register routing handlers
  final mediator = Mediator();

  // 1. Auth Registrations
  final IAuthRepository authRepo = AuthRepository();
  mediator.registerHandler<LoginCommand, AuthSession?>(
      LoginCommandHandler(authRepo));
  mediator.registerHandler<LogoutCommand, void>(LogoutCommandHandler(authRepo));
  mediator.registerHandler<CheckTokenQuery, AuthSession?>(
      CheckTokenQueryHandler(authRepo));
  mediator.registerHandler<CheckPermissionsQuery, bool>(
      CheckPermissionsQueryHandler(authRepo));
  mediator.registerHandler<RequestPermissionsCommand, bool>(
      RequestPermissionsCommandHandler(authRepo));

  // 2. Attendance Registrations
  final IAttendanceRepository attendanceRepo = AttendanceRepository();
  mediator.registerHandler<CheckInCommand, bool>(
      CheckInCommandHandler(attendanceRepo));
  mediator.registerHandler<CheckOutCommand, bool>(
      CheckOutCommandHandler(attendanceRepo));
  mediator.registerHandler<GetAttendanceHistoryQuery, List<ActivityLogItem>>(
      GetAttendanceHistoryQueryHandler(attendanceRepo));

  // 3. Leave Registrations
  final ILeaveRepository leaveRepo = LeaveRepository();
  mediator.registerHandler<SubmitLeaveCommand, bool>(
      SubmitLeaveCommandHandler(leaveRepo));
  mediator.registerHandler<GetLeavesQuery, List<LeaveRequest>>(
      GetLeavesQueryHandler(leaveRepo));
  mediator.registerHandler<GetSupervisorsQuery, List<Supervisor>>(
      GetSupervisorsQueryHandler(leaveRepo));

  // 4. Payroll Registrations
  final IPayrollRepository payrollRepo = PayrollRepository();
  mediator.registerHandler<GetSalarySlipQuery, PayrollData?>(
      GetSalarySlipQueryHandler(payrollRepo));

  runApp(
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
}

class HrPortalApp extends StatelessWidget {
  const HrPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: ApiClient.scaffoldMessengerKey,
      title: 'HR Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(context),
      home: const SplashPage(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = Provider.of<AuthBloc>(context);

    if (authBloc.isLoggedIn) {
      return const MainShell();
    } else {
      return const LoginPage();
    }
  }
}
