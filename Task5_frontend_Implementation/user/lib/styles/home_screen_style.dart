import 'package:flutter/material.dart';

class HomeScreenStyle {
  // Color Palette
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFF44336);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color shadowColor = Color(0x1A000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFBFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );

  static const TextStyle valueText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle labelText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: shadowColor,
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: shadowColor,
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // Elevations
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: cardShadow,
    border: Border.all(
      color: Colors.grey.withOpacity(0.1),
      width: 1,
    ),
  );

  // Metric Card Decoration
  static BoxDecoration get metricCardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusM),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 6,
        offset: Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.grey.withOpacity(0.05),
      width: 1,
    ),
  );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryBlue,
    padding: EdgeInsets.symmetric(horizontal: paddingL, vertical: paddingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: elevationMedium,
    shadowColor: primaryBlue.withOpacity(0.3),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: primaryBlue,
    backgroundColor: lightBlue,
    padding: EdgeInsets.symmetric(horizontal: paddingL, vertical: paddingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: elevationLow,
    shadowColor: primaryBlue.withOpacity(0.2),
  );

  // Status Colors
  static Color getSignalColor(int signalStrength) {
    if (signalStrength >= -70) return accentGreen;
    if (signalStrength >= -85) return accentOrange;
    return accentRed;
  }

  static Color getLatencyColor(int latency) {
    if (latency <= 50) return accentGreen;
    if (latency <= 100) return accentOrange;
    return accentRed;
  }

  static Color getPacketLossColor(double packetLoss) {
    if (packetLoss <= 1.0) return accentGreen;
    if (packetLoss <= 3.0) return accentOrange;
    return accentRed;
  }

  // Icon Styles
  static IconData getSignalIcon(int signalStrength) {
    if (signalStrength >= -70) return Icons.signal_cellular_4_bar;
    if (signalStrength >= -85) return Icons.signal_cellular_0_bar;
    if (signalStrength >= -100) return Icons.signal_cellular_0_bar;
    return Icons.signal_cellular_0_bar;
  }

  // Responsive Design Breakpoints
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) return paddingXL;
    if (isTablet(context)) return paddingL;
    return paddingM;
  }

  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  // Custom Animations
  static Widget buildFadeInAnimation({
    required Widget child,
    required Animation<double> animation,
    Duration delay = Duration.zero,
  }) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Interval(
          delay.inMilliseconds / 1000.0,
          1.0,
          curve: Curves.easeInOut,
        ),
      )),
      child: child,
    );
  }

  static Widget buildSlideInAnimation({
    required Widget child,
    required Animation<double> animation,
    Duration delay = Duration.zero,
    Offset begin = const Offset(0, 0.5),
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Interval(
          delay.inMilliseconds / 1000.0,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: child,
    );
  }
}