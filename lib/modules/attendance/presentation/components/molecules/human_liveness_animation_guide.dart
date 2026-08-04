import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated Apple Face ID Style Liveness Guidance Overlay
/// Features 3D head turning rotation ("Tengok Kiri"), Apple Face ID vector face line art,
/// 4 corner scanning brackets, laser sweep line, directional arrow badge, and success checkmark morph.
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
    final primaryColor = isSuccess ? const Color(0xFF34C759) : const Color(0xFF007AFF);

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        final animValue = widget.animationController.value;

        // Smooth sinusoidal 3D head rotation Y angle turning left:
        // Range: 0.0 rad to -0.55 rad (~-32 degrees left turn)
        final headRotationY = -math.sin(animValue * math.pi) * 0.55;

        // Arrow sliding movement pointing left
        final arrowTranslateX = -math.sin(animValue * math.pi) * 12.0;

        return Stack(
          alignment: Alignment.center,
          children: [


            // 3. Sweeping Laser Scan Line
            if (!isSuccess)
              Positioned(
                top: 25 + (170 * animValue),
                left: 30,
                right: 30,
                child: Container(
                  height: 3.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.0),
                        primaryColor.withOpacity(0.85),
                        primaryColor.withOpacity(0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.7),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Center 3D Apple Face ID Vector Avatar (Turns left & morphs on success)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.elasticOut,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: isSuccess
                  ? Container(
                      key: const ValueKey('success_face_id'),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF34C759).withOpacity(0.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF34C759),
                          size: 72,
                        ),
                      ),
                    )
                  : Transform(
                      key: const ValueKey('scanning_face_id'),
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012) // 3D Perspective Depth
                        ..rotateY(headRotationY)  // Rotate left on Y axis
                        ..rotateZ(-headRotationY * 0.1), // Organic tilt
                      child: CustomPaint(
                        size: const Size(110, 110),
                        painter: _FaceIdVectorPainter(
                          pulse: animValue,
                          color: primaryColor,
                          headRotationY: headRotationY,
                          isSuccess: isSuccess,
                        ),
                      ),
                    ),
            ),

            // 5. Floating Guidance Badge ("← Tengok Kiri")
            Positioned(
              top: 14,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !isSuccess
                    ? Transform.translate(
                        key: const ValueKey('badge_turning'),
                        offset: Offset(arrowTranslateX, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0052CC),
                                Color(0xFF007AFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007AFF).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        key: const ValueKey('badge_success'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34C759).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Wajah Terverifikasi',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom Painter for 3D Apple Face ID Vector Face Line Art
class _FaceIdVectorPainter extends CustomPainter {
  final double pulse;
  final Color color;
  final double headRotationY;
  final bool isSuccess;

  _FaceIdVectorPainter({
    required this.pulse,
    required this.color,
    required this.headRotationY,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isSuccess) return;

    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 3.2;

    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    // 3D parallax depth shifts (features move left as head turns left)
    final parallaxX = (headRotationY / -0.55) * -16.0;
    final deepParallaxX = (headRotationY / -0.55) * -22.0;

    // Outer Face ID Rounded Oval Frame
    final faceRect = Rect.fromCenter(
      center: Offset(center.dx + parallaxX * 0.5, center.dy),
      width: 76,
      height: 90,
    );
    final faceRRect = RRect.fromRectAndRadius(faceRect, const Radius.circular(28));
    final framePaint = Paint()
      ..color = color.withOpacity(0.4 + 0.15 * math.sin(pulse * math.pi))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(faceRRect, framePaint);

    // 1. Eyes (Left and Right Eyes)
    final eyeY = center.dy - 12;
    final leftEyePos = Offset(center.dx - 18 + deepParallaxX, eyeY);
    final rightEyePos = Offset(center.dx + 18 + deepParallaxX, eyeY);

    // Left eye arc/dot
    canvas.drawCircle(leftEyePos, 4.0, fillPaint);
    // Right eye arc/dot
    canvas.drawCircle(rightEyePos, 4.0, fillPaint);

    // 2. Face ID Nose Line Art
    final nosePath = Path()
      ..moveTo(center.dx + deepParallaxX, eyeY + 6)
      ..lineTo(center.dx - 3 + deepParallaxX, center.dy + 6)
      ..lineTo(center.dx + 5 + deepParallaxX, center.dy + 8);
    canvas.drawPath(nosePath, paint);

    // 3. Smiling Mouth Curve Line
    final mouthPath = Path();
    final mouthCenter = Offset(center.dx + deepParallaxX, center.dy + 22);
    mouthPath.moveTo(mouthCenter.dx - 14, mouthCenter.dy - 2);
    mouthPath.quadraticBezierTo(
      mouthCenter.dx,
      mouthCenter.dy + 12,
      mouthCenter.dx + 14,
      mouthCenter.dy - 2,
    );
    canvas.drawPath(mouthPath, paint);
  }

  @override
  bool shouldRepaint(covariant _FaceIdVectorPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.color != color ||
        oldDelegate.headRotationY != headRotationY ||
        oldDelegate.isSuccess != isSuccess;
  }
}


