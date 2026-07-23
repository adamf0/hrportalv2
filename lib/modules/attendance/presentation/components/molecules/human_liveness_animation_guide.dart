import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated Human Liveness Guidance Overlay for Camera Preview
/// Displays interactive vector head turning animation, left directional guide arrow,
/// face mesh landmark indicators, and real-time scanning laser line.
class HumanLivenessAnimationGuide extends StatefulWidget {
  final AnimationController animationController;
  final double progress;
  final String detectionStatus;

  const HumanLivenessAnimationGuide({
    super.key,
    required this.animationController,
    required this.progress,
    required this.detectionStatus,
  });

  @override
  State<HumanLivenessAnimationGuide> createState() =>
      _HumanLivenessAnimationGuideState();
}

class _HumanLivenessAnimationGuideState
    extends State<HumanLivenessAnimationGuide> {
  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.progress >= 1.0;
    final primaryColor = isSuccess ? Colors.green : const Color(0xFF0052CC);

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        final animValue = widget.animationController.value;
        // Head turn angle back and forth towards left (-0.45 rad = ~-25 degrees)
        final headRotationY = -math.sin(animValue * math.pi) * 0.45;
        final arrowTranslateX = -math.sin(animValue * math.pi) * 16.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Face Frame Oval Border (Scanning Contour)
            CustomPaint(
              size: const Size(220, 220),
              painter: _FaceContourPainter(
                progress: widget.progress,
                color: isSuccess ? Colors.green : const Color(0xFF0052CC),
                pulse: animValue,
              ),
            ),

            // Sweeping Laser Scan Line
            Positioned(
              top: 20 + (180 * animValue),
              left: 30,
              right: 30,
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.0),
                      primaryColor.withOpacity(0.8),
                      primaryColor.withOpacity(0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Interactive Directional Arrow & Guidance Badge ("Tengok Kiri ⬅️")
            if (!isSuccess)
              Positioned(
                top: 22,
                child: Transform.translate(
                  offset: Offset(arrowTranslateX, 0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tengok Kiri',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Positioned(
                top: 22,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Verifikasi Sukses',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Custom Painter for Oval Face Placement Contour & Progress Ring
class _FaceContourPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double pulse;

  _FaceContourPainter({
    required this.progress,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.82,
      height: size.height * 0.92,
    );

    // Background dashed/dotted contour path
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(rect, bgPaint);

    // Active Glowing Contour Oval
    final activePaint = Paint()
      ..color = color.withOpacity(0.7 + (0.3 * math.sin(pulse * math.pi)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceContourPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.color != color;
  }
}

/// Custom Painter for Facial Landmark Mesh Points
class _FaceMeshPainter extends CustomPainter {
  final Color color;
  final double pulse;

  _FaceMeshPainter({required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 + (0.3 * math.sin(pulse * math.pi)))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Relative landmark points for face mesh (left eye, right eye, nose tip, mouth corners, chin)
    final points = [
      Offset(size.width * 0.35, size.height * 0.38), // Left Eye
      Offset(size.width * 0.65, size.height * 0.38), // Right Eye
      Offset(size.width * 0.50, size.height * 0.52), // Nose
      Offset(size.width * 0.40, size.height * 0.68), // Left Mouth Corner
      Offset(size.width * 0.60, size.height * 0.68), // Right Mouth Corner
      Offset(size.width * 0.50, size.height * 0.82), // Chin
    ];

    // Draw mesh connection lines
    canvas.drawLine(points[0], points[1], linePaint);
    canvas.drawLine(points[0], points[2], linePaint);
    canvas.drawLine(points[1], points[2], linePaint);
    canvas.drawLine(points[2], points[3], linePaint);
    canvas.drawLine(points[2], points[4], linePaint);
    canvas.drawLine(points[3], points[4], linePaint);
    canvas.drawLine(points[3], points[5], linePaint);
    canvas.drawLine(points[4], points[5], linePaint);

    // Draw glowing landmark dots
    for (var pt in points) {
      canvas.drawCircle(pt, 3.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceMeshPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.color != color;
  }
}
