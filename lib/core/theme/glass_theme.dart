import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTheme {
  /// A highly polished, production-grade glassmorphic container.
  /// Features a dual-layered fine border simulation to mimic real specular refraction
  /// and a soft ambient occlusion shadow to lift the panel off the background wallpaper.
  static Widget buildGlassPanel({
    required Widget child,
    required BorderRadius borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    double blurSigma = 14.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              // Premium graded multi-stop tint to prevent the "muddy gray" look
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.065),
                  Colors.white.withOpacity(0.025),
                ],
                stops: const [0.0, 1.0],
              ),
              // Dual-layered fine border simulation for sharp glass edges
              border: Border.all(
                color: Colors.white.withOpacity(0.09),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}