import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hrportalv2/core/responsive_helper.dart';
import 'package:hrportalv2/modules/auth/presentation/auth_bloc.dart';
import 'package:hrportalv2/main.dart';

// Modular Molecule Component
import 'package:hrportalv2/modules/auth/presentation/components/molecules/permission_tile_card.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  Timer? _checkTimer;
  bool _locationGranted = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
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
    if (!mounted) return;
    await context.read<AuthBloc>().verifyPermissions();
    
    // We can also query local status to update state variables _locationGranted and _cameraGranted
    final locStatus = await checkIndividualLocationPermission();
    final camStatus = await checkIndividualCameraPermission();
    
    if (mounted) {
      setState(() {
        _locationGranted = locStatus;
        _cameraGranted = camStatus;
      });

      if (locStatus && camStatus) {
        _checkTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthenticationWrapper()),
        );
      }
    }
  }

  Future<bool> checkIndividualLocationPermission() async {
    try {
      final locPermission = await Geolocator.checkPermission();
      return locPermission == LocationPermission.always || 
             locPermission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkIndividualCameraPermission() async {
    try {
      final cameras = await getAvailableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(cameras.first, ResolutionPreset.low);
        await controller.initialize();
        await controller.dispose();
        return true;
      }
    } catch (e) {
      if (e is CameraException && e.code == 'cameraPermission') {
        return false;
      }
    }
    return true; // default busy/granted
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
      final cameras = await getAvailableCameras();
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textDark = Theme.of(context).colorScheme.onSurface;
    final textGrey = Theme.of(context).colorScheme.secondary;
    final background = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
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
              PermissionTileCard(
                icon: Icons.location_on,
                title: 'Akses Lokasi (GPS)',
                description: 'Digunakan untuk validasi keberadaan di radius kampus.',
                isGranted: _locationGranted,
                onRequestTap: _requestLocation,
              ),
              const SizedBox(height: 12),
              PermissionTileCard(
                icon: Icons.camera_alt,
                title: 'Akses Kamera',
                description: 'Digunakan untuk deteksi keaktifan/liveness wajah.',
                isGranted: _cameraGranted,
                onRequestTap: _requestCamera,
              ),
              SizedBox(height: context.h(24)),
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

// Available cameras mock check helper
Future<List<CameraDescription>> getAvailableCameras() async {
  try {
    return await availableCameras();
  } catch (_) {
    return [];
  }
}
