import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../core/responsive_helper.dart';
import 'dashboard_page.dart';
import 'attendance_page.dart';
import 'leave_list_page.dart';
import 'salary_slip_page.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Pages corresponding to bottom nav
    final List<Widget> pages = [
      const DashboardPage(),
      const AttendancePage(),
      const LeaveListPage(),
      const SalarySlipPage(),
    ];


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: IndexedStack(
        index: appState.currentTabIndex,
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
                appState: appState,
              ),
              _buildBottomNavItem(
                context,
                index: 1,
                icon: Icons.face_retouching_natural,
                label: 'Attendance',
                appState: appState,
              ),
              _buildBottomNavItem(
                context,
                index: 2,
                icon: Icons.assignment_outlined,
                label: 'Requests',
                appState: appState,
              ),
              _buildBottomNavItem(
                context,
                index: 3,
                icon: Icons.payments_outlined,
                label: 'Payroll',
                appState: appState,
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
    required AppState appState,
  }) {
    final isSelected = appState.currentTabIndex == index;
    final bool isWatch = context.isWatch;
    
    if (isWatch) {
      return GestureDetector(
        onTap: () => appState.setTabIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF003D9B) : const Color(0xFF535F73),
            size: 20,
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () => appState.setTabIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD7E3FB) : Colors.transparent, // Capsule background
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF101C2D) : const Color(0xFF535F73),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF101C2D),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
