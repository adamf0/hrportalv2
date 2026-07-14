import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import '../core/responsive_helper.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _locationGranted = false;
  bool _cameraGranted = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // Run a periodic check to automatically dismiss the screen once permissions are granted
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkPermissions();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    bool hasLoc = false;
    bool hasCam = false;

    try {
      final locPermission = await Geolocator.checkPermission();
      hasLoc = locPermission == LocationPermission.always || 
               locPermission == LocationPermission.whileInUse;
    } catch (_) {}

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(cameras.first, ResolutionPreset.low);
        await controller.initialize();
        await controller.dispose();
        hasCam = true;
      }
    } catch (e) {
      if (e is CameraException && e.code == 'cameraPermission') {
        hasCam = false;
      } else {
        hasCam = true; // granted but busy
      }
    }

    if (mounted) {
      setState(() {
        _locationGranted = hasLoc;
        _cameraGranted = hasCam;
      });

      // If both are granted, automatically navigate away!
      if (hasLoc && hasCam) {
        _checkTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthenticationWrapper()),
        );
      }
    }
  }

  Future<void> _requestLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
      _checkPermissions();
    } catch (_) {}
  }

  Future<void> _requestCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(cameras.first, ResolutionPreset.low);
        await controller.initialize();
        await controller.dispose();
      }
      _checkPermissions();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF003D9B);
    const textDark = Color(0xFF191C1E);
    const textGrey = Color(0xFF535F73);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              // Header title
              Icon(Icons.security, size: 72, color: primaryColor.withOpacity(0.8)),
              const SizedBox(height: 24),
              Text(
                'Izin Aplikasi Dibutuhkan',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: context.sp(24),
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Untuk menggunakan fitur absensi dan verifikasi wajah Universitas Pakuan, mohon aktifkan izin akses berikut:',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: context.sp(13),
                  color: textGrey,
                  height: 1.4,
                ),
              ),
              SizedBox(height: context.h(24)),

              // Location card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(context.isWatch ? 10 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _locationGranted ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: _locationGranted ? Colors.green : Colors.red,
                              size: context.w(20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Akses Lokasi (GPS)',
                              style: GoogleFonts.inter(
                                fontSize: context.sp(14),
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                          if (!_locationGranted)
                            TextButton(
                              onPressed: _requestLocation,
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Izinkan', style: GoogleFonts.inter(fontSize: context.sp(12))),
                            )
                          else
                            Icon(Icons.check_circle, color: Colors.green, size: context.w(20)),
                        ],
                      ),
                      if (!context.isWatch) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Digunakan untuk validasi keberadaan di radius kampus.',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(11),
                            color: textGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Camera card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(context.isWatch ? 10 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _cameraGranted ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: _cameraGranted ? Colors.green : Colors.red,
                              size: context.w(20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Akses Kamera',
                              style: GoogleFonts.inter(
                                fontSize: context.sp(14),
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                          if (!_cameraGranted)
                            TextButton(
                              onPressed: _requestCamera,
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Izinkan', style: GoogleFonts.inter(fontSize: context.sp(12))),
                            )
                          else
                            Icon(Icons.check_circle, color: Colors.green, size: context.w(20)),
                        ],
                      ),
                      if (!context.isWatch) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Digunakan untuk deteksi keaktifan/liveness wajah.',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(11),
                            color: textGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(24)),

              // Quick bypass reminder or manual check trigger button
              ElevatedButton(
                onPressed: _checkPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: context.isWatch ? 10 : 16),
                  minimumSize: const Size(double.infinity, 0),
                  elevation: 0,
                ),
                child: Text(
                  'Periksa Ulang Izin',
                  style: GoogleFonts.inter(
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
