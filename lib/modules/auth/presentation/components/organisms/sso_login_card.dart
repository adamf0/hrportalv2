import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class SsoLoginCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLoginTap;

  const SsoLoginCard({
    super.key,
    required this.isLoading,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final outlineVariant = Theme.of(context).colorScheme.outlineVariant;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.all(context.isWatch ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Single Sign-On',
            style: GoogleFonts.inter(
              fontSize: context.sp(13),
              fontWeight: FontWeight.bold,
              color: onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: onLoginTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: context.isWatch ? 10 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.badge_outlined, size: context.w(20)),
                  label: Text(
                    'Masuk dengan Unpak SSO',
                    style: GoogleFonts.inter(
                      fontSize: context.sp(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
