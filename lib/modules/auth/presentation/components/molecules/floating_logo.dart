import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class FloatingLogo extends StatelessWidget {
  final AnimationController floatController;
  final VoidCallback onDoubleTap;

  const FloatingLogo({
    super.key,
    required this.floatController,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        GestureDetector(
          onDoubleTap: onDoubleTap,
          child: AnimatedBuilder(
            animation: floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -6 * floatController.value),
                child: child,
              );
            },
            child: Container(
              width: context.w(64),
              height: context.w(64),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.corporate_fare,
                color: Colors.white,
                size: context.w(36),
              ),
            ),
          ),
        ),
        SizedBox(height: context.h(16)),
        Text(
          'HR Portal',
          style: GoogleFonts.inter(
            fontSize: context.sp(22),
            fontWeight: FontWeight.w600,
            color: primaryColor,
            letterSpacing: -0.01,
          ),
        ),
      ],
    );
  }
}
