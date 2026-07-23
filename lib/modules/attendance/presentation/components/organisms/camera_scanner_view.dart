import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:hrportalv2/core/responsive_helper.dart';
import 'package:hrportalv2/modules/attendance/presentation/attendance_bloc.dart';
import '../molecules/human_liveness_animation_guide.dart';

class CameraScannerView extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController? cameraController;
  final double progress;
  final String detectionStatus;
  final AnimationController pulseController;
  final VoidCallback onRefreshTap;
  final VoidCallback onHelpTap;

  const CameraScannerView({
    super.key,
    required this.isCameraInitialized,
    required this.cameraController,
    required this.progress,
    required this.detectionStatus,
    required this.pulseController,
    required this.onRefreshTap,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    final attendanceBloc = Provider.of<AttendanceBloc>(context);
    final ip = attendanceBloc.useRealNetworkAndGps
        ? attendanceBloc.realIp
        : attendanceBloc.simulatedIp;
    final lat = attendanceBloc.useRealNetworkAndGps
        ? attendanceBloc.realLatitude
        : attendanceBloc.simulatedLatitude;
    final lon = attendanceBloc.useRealNetworkAndGps
        ? attendanceBloc.realLongitude
        : attendanceBloc.simulatedLongitude;

    final isG = attendanceBloc.isFakeGps;
    final isV = attendanceBloc.isVpn;
    final noteList = <String>[];
    if (isG) noteList.add('G');
    if (isV) noteList.add('V');
    final noteStr =
        noteList.isEmpty ? '-' : noteList.map((e) => '[$e]').join(', ');

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.isWatch ? 10.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                'Verifikasi Liveness',
                style: GoogleFonts.inter(
                  fontSize: context.sp(22),
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Silakan tengokkan kepala Anda secara perlahan ke arah kiri untuk verifikasi kehadiran.',
                style: GoogleFonts.inter(
                  fontSize: context.sp(13),
                  color: onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              SizedBox(height: context.h(24)),
              Center(
                child: Container(
                  width: context.isWatch ? 140 : 260,
                  height: context.isWatch ? 140 : 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isCameraInitialized && cameraController != null)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width:
                                  cameraController?.value.previewSize?.height ??
                                      1280.0,
                              height:
                                  cameraController?.value.previewSize?.width ??
                                      720.0,
                              child: CameraPreview(cameraController!),
                            ),
                          )
                        else
                          Container(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 10,
                              ),
                              itemBuilder: (context, index) => Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        HumanLivenessAnimationGuide(
                          animationController: pulseController,
                          progress: progress,
                          detectionStatus: detectionStatus,
                        ),
                        SizedBox(
                          width: context.isWatch ? 120 : 240,
                          height: context.isWatch ? 120 : 240,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5,
                            backgroundColor: Colors.grey[300]!.withOpacity(0.4),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0 ? Colors.green : primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(context.isWatch ? 8.0 : 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress Deteksi',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.w500,
                            color: onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: context.isWatch ? 4 : 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology,
                            size: context.w(16), color: primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            detectionStatus,
                            style: GoogleFonts.inter(
                              fontSize: context.sp(11),
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.network_ping, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'ip: ',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.bold,
                            color: onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ip,
                            style: GoogleFonts.inter(
                              fontSize: context.sp(12),
                              color: onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'gps: ',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.bold,
                            color: onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                            style: GoogleFonts.inter(
                              fontSize: context.sp(12),
                              color: onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.security_outlined,
                            size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'note: ',
                          style: GoogleFonts.inter(
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.bold,
                            color: onSurfaceVariant,
                          ),
                        ),
                        Text(
                          noteStr,
                          style: GoogleFonts.inter(
                            fontSize: context.sp(12),
                            color: (isG || isV) ? Colors.red : onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefreshTap,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[350]!),
                  padding: EdgeInsets.symmetric(
                      vertical: context.isWatch ? 8.0 : 14.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.refresh, color: onSurfaceVariant, size: 18),
                label: Text(
                  'Ulangi Deteksi',
                  style: GoogleFonts.inter(
                    color: onSurfaceVariant,
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onHelpTap,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[350]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon:
                    Icon(Icons.help_outline, color: onSurfaceVariant, size: 18),
                label: Text(
                  'Butuh Bantuan?',
                  style: GoogleFonts.inter(
                    color: onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
