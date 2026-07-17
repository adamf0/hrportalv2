import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import '../modules/attendance/presentation/attendance_bloc.dart';
import '../core/responsive_helper.dart';
import '../modules/dashboard/presentation/pages/dashboard_page.dart';
import '../modules/attendance/presentation/components/pages/attendance_page.dart';
import '../modules/leave/presentation/components/pages/leave_list_page.dart';
import '../modules/payroll/presentation/components/pages/salary_slip_page.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceBloc = Provider.of<AttendanceBloc>(context);
    
    final List<Widget> pages = [
      const DashboardPage(),
      const AttendancePage(),
      const LeaveListPage(),
      const SalarySlipPage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: IndexedStack(
        index: attendanceBloc.currentTabIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        height: context.isWatch ? 50 : 80,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                context,
                index: 0,
                icon: Icons.dashboard,
                label: 'Home',
                attendanceBloc: attendanceBloc,
              ),
              _buildBottomNavItem(
                context,
                index: 1,
                icon: Icons.face_retouching_natural,
                label: 'Attendance',
                attendanceBloc: attendanceBloc,
              ),
              _buildBottomNavItem(
                context,
                index: 2,
                icon: Icons.assignment_outlined,
                label: 'Requests',
                attendanceBloc: attendanceBloc,
              ),
              _buildBottomNavItem(
                context,
                index: 3,
                icon: Icons.payments_outlined,
                label: 'Payroll',
                attendanceBloc: attendanceBloc,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required AttendanceBloc attendanceBloc,
  }) {
    final isSelected = attendanceBloc.currentTabIndex == index;
    final bool isWatch = context.isWatch;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    
    if (isWatch) {
      return GestureDetector(
        onTap: () => attendanceBloc.setTabIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: isSelected ? primaryColor : secondaryColor,
            size: 20,
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () => attendanceBloc.setTabIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.infoContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : secondaryColor,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
