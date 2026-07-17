import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/responsive_helper.dart';

class ResponsiveDateRangeRow extends StatelessWidget {
  final Widget startWidget;
  final Widget endWidget;

  const ResponsiveDateRangeRow({
    super.key,
    required this.startWidget,
    required this.endWidget,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.secondary;

    return Flex(
      direction: context.isWatch ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: context.isWatch ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: [
        context.isWatch ? startWidget : Expanded(child: startWidget),
        SizedBox(
          width: context.isWatch ? 0 : 8,
          height: context.isWatch ? 6 : 0,
        ),
        Center(
          child: Text(
            's/d',
            style: GoogleFonts.inter(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          width: context.isWatch ? 0 : 8,
          height: context.isWatch ? 6 : 0,
        ),
        context.isWatch ? endWidget : Expanded(child: endWidget),
      ],
    );
  }
}
