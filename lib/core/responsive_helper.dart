import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  // Watch screen size check (< 280px)
  bool get isWatch => screenWidth < 280;
  
  // Phone and Tablet breakpoints
  bool get isSmallPhone => screenWidth >= 280 && screenWidth < 340;
  bool get isMediumPhone => screenWidth >= 340 && screenWidth < 450;
  bool get isTablet => screenWidth >= 450 && screenWidth < 800;
  bool get isDesktop => screenWidth >= 800;

  // Responsive scaling factor compared to a standard 375px baseline
  double get scaleFactor {
    double width = screenWidth;
    if (width < 200) width = 200; // Watch screen floor limit
    double factor = width / 375.0;
    
    // Clamp to prevent elements from getting too small or too massive
    if (isWatch) {
      return factor.clamp(0.45, 0.7);
    }
    return factor.clamp(0.65, 1.35);
  }

  // Scale Font Sizes (sp)
  double sp(double baseSize) {
    if (isWatch) {
      return (baseSize * scaleFactor * 0.9).clamp(7.5, baseSize * 0.8);
    }
    return (baseSize * scaleFactor).clamp(baseSize * 0.7, baseSize * 1.4);
  }

  // Scale Width/Horizontal dimensions (w)
  double w(double baseSize) {
    return baseSize * scaleFactor;
  }

  // Scale Height/Vertical dimensions (h)
  double h(double baseSize) {
    double heightFactor = screenHeight / 812.0;
    if (isWatch) {
      return baseSize * 0.55;
    }
    return baseSize * heightFactor.clamp(0.7, 1.3);
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
    return const EdgeInsets.all(16.0);
  }
}
