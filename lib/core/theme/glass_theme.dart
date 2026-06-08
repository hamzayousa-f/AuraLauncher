import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTheme {
  // Frosted glass blur configurations
  static const double blurX = 15.0;
  static const double blurY = 15.0;

  // Background opacities
  static final Color glassColor = Colors.white.withOpacity(0.08);
  static final Color glassBorderColor = Colors.white.withOpacity(0.18);

  // Reusable border style for that crisp glass reflection edge
  static Border glassBorder = Border.all(color: glassBorderColor, width: 1.2);

  // Standard shadow to give glass depth over dynamic wallpapers
  static List<BoxShadow> glassShadows = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Helper widget to easily wrap any widget into a uniform Glass Container
  static Widget buildGlassPanel({
    required Widget child,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: radius,
            border: glassBorder,
            boxShadow: glassShadows,
          ),
          child: child,
        ),
      ),
    );
  }
}
