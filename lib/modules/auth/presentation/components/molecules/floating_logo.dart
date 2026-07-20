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
              width: context.w(80),
              height: context.w(80),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'asset_app/logo-transparent.png',
                    fit: BoxFit.contain,
                  ),
                ),
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
