import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import '../core/responsive_helper.dart';
import 'permission_page.dart';

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
    // Wait for splash duration
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Check permissions
    bool hasLocation = false;
    bool hasCamera = false;

    try {
      final locPermission = await Geolocator.checkPermission();
      hasLocation = locPermission == LocationPermission.always || 
                    locPermission == LocationPermission.whileInUse;
    } catch (_) {}

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(cameras.first, ResolutionPreset.low);
        await controller.initialize();
        await controller.dispose();
        hasCamera = true;
      }
    } catch (e) {
      if (e is CameraException && e.code == 'cameraPermission') {
        hasCamera = false;
      } else {
        hasCamera = true; // Other errors imply permission is granted but busy
      }
    }

    if (!mounted) return;

    if (!hasLocation || !hasCamera) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PermissionPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthenticationWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF003D9B);

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
                // Logo
                Container(
                  width: context.w(110),
                  height: context.w(110),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/unpak_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.domain,
                          size: context.w(50),
                          color: primaryColor,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: context.h(24)),
                // App Name
                Text(
                  'HR CONNECT',
                  style: GoogleFonts.outfit(
                    fontSize: context.sp(28),
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: context.h(8)),
                // Subtitle
                Text(
                  'Universitas Pakuan',
                  style: GoogleFonts.inter(
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF535F73),
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: context.h(48)),
                // Loading indicator
                SizedBox(
                  width: context.w(24),
                  height: context.w(24),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
