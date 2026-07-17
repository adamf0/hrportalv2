import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                'Bahasa Indonesia',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 12,
              color: Colors.grey[300],
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'English',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© 2024 HR Portal Solutions. All rights reserved.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
