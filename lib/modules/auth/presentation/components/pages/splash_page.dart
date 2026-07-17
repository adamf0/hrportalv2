import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';
import 'package:hrportalv2/modules/auth/presentation/auth_bloc.dart';
import 'permission_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final authBloc = context.read<AuthBloc>();
    await authBloc.checkSessionAndPermissions();

    if (!mounted) return;

    if (!authBloc.isPermissionsGranted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PermissionPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: context.pagePadding,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bubble_chart,
                    size: 80,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'HR CONNECT',
                  style: GoogleFonts.outfit(
                    fontSize: context.sp(28),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Universitas Pakuan Smart Portal',
                  style: GoogleFonts.inter(
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: context.w(150),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    child: LinearProgressIndicator(
                      color: primaryColor,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Memuat data...',
                  style: GoogleFonts.inter(
                    fontSize: context.sp(12),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
