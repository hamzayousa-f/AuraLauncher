import 'dart:io';
import 'package:flutter/material.dart';

class WallpaperBackground extends StatelessWidget {
  final Widget child;
  final VoidCallback onLongPressHome;
  final String wallpaperType; // 'asset' or 'file'
  final String wallpaperPath;

  const WallpaperBackground({
    super.key,
    required this.child,
    required this.onLongPressHome,
    required this.wallpaperType,
    required this.wallpaperPath,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider backgroundImage;

    if (wallpaperType == 'file' && wallpaperPath.isNotEmpty) {
      backgroundImage = FileImage(File(wallpaperPath));
    } else if (wallpaperPath.isNotEmpty) {
      backgroundImage = AssetImage(wallpaperPath);
    } else {
      // Clean fallback dark cinematic gradient if no wallpaper is set
      backgroundImage = const AssetImage('assets/wallpapers/default_noir.jpg');
    }

    return GestureDetector(
      onLongPress: onLongPressHome,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Background Wallpaper Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: backgroundImage, fit: BoxFit.cover),
            ),
          ),
          // Subtle dark cinematic overlay to protect typography readability
          Container(color: Colors.black.withOpacity(0.45)),
          // Main UI Layer Content
          child,
        ],
      ),
    );
  }
}
