import 'dart:io';
import 'package:flutter/material.dart';

class WallpaperBackground extends StatelessWidget {
  final String wallpaperType;
  final String wallpaperPath;
  final Widget child;
  final VoidCallback onLongPressHome;

  const WallpaperBackground({
    super.key,
    required this.wallpaperType,
    required this.wallpaperPath,
    required this.child,
    required this.onLongPressHome,
  });

  @override
  Widget build(BuildContext context) {
    Widget backgroundWidget;

    // Strict Type Branching Configuration
    if (wallpaperType == 'file' && wallpaperPath.isNotEmpty && !wallpaperPath.startsWith('0x')) {
      final file = File(wallpaperPath);
      if (file.existsSync()) {
        backgroundWidget = Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        // Fallback if target storage file was wiped or unlinked
        backgroundWidget = Container(color: const Color(0xFF0A0A0A));
      }
    } else if (wallpaperType == 'solid') {
      // Safely parse hex string back into native ARGB integers
      final int colorValue = int.tryParse(wallpaperPath) ?? 0xFF0A0A0A;
      backgroundWidget = Container(color: Color(colorValue));
    } else {
      // Default systemic fallback container matching the dark setup
      backgroundWidget = Container(color: const Color(0xFF0A0A0A));
    }

    return GestureDetector(
      onLongPress: onLongPressHome,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned.fill(child: backgroundWidget),
          child,
        ],
      ),
    );
  }
}