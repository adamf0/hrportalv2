import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Device classification breakpoints
  bool get isWatch => screenWidth < 280;
  bool get isSmallPhone => screenWidth >= 280 && screenWidth < 340;
  bool get isMediumPhone => screenWidth >= 340 && screenWidth < 450;
  bool get isTablet => screenWidth >= 450 && screenWidth < 800;
  bool get isDesktop => screenWidth >= 800;

  // Responsive scaling factor compared to standard 375px baseline
  double get scaleFactor {
    double width = screenWidth;
    if (width < 200) width = 200; // Watch screen floor limit
    double factor = width / 375.0;

    if (isWatch) {
      return factor.clamp(0.45, 0.7);
    }
    return factor.clamp(0.65, 1.35);
  }

  // Scale Font Sizes (sp) - Responsive Typography
  double sp(double baseSize) {
    if (isWatch) {
      return (baseSize * scaleFactor * 0.9).clamp(7.5, baseSize * 0.8);
    }
    return (baseSize * scaleFactor).clamp(baseSize * 0.7, baseSize * 1.4);
  }

  // Scale Width / Spacing (w / dp)
  double w(double baseSize) {
    return baseSize * scaleFactor;
  }

  double dp(double baseSize) {
    return baseSize * scaleFactor;
  }

  // Scale Height / Vertical Spacing (h)
  double h(double baseSize) {
    double heightFactor = screenHeight / 812.0;
    if (isWatch) {
      return baseSize * 0.55;
    }
    return baseSize * heightFactor.clamp(0.7, 1.3);
  }

  // Responsive padding helpers
  EdgeInsets responsiveInsets({double h = 16, double v = 16}) {
    if (isWatch) {
      return const EdgeInsets.symmetric(horizontal: 6, vertical: 6);
    }
    return EdgeInsets.symmetric(horizontal: w(h), vertical: this.h(v));
  }

  EdgeInsets responsiveAll(double val) {
    if (isWatch) {
      return const EdgeInsets.all(6.0);
    }
    return EdgeInsets.all(w(val));
  }

  // Adaptive standard page padding margins
  EdgeInsets get pagePadding {
    if (isWatch) {
      return const EdgeInsets.all(6.0);
    } else if (isSmallPhone) {
      return const EdgeInsets.all(10.0);
    } else if (isTablet) {
      return const EdgeInsets.all(22.0);
    } else if (isDesktop) {
      return const EdgeInsets.all(28.0);
    }
    return EdgeInsets.all(w(16.0));
  }
}
