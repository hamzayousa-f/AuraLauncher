import 'package:flutter/material.dart';

class WallpaperBackground extends StatelessWidget {
  final Widget child;
  final VoidCallback onLongPressHome;

  const WallpaperBackground({
    super.key,
    required this.child,
    required this.onLongPressHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Detects long presses on any empty space of the home screen layout
        onLongPress: onLongPressHome,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Layer 1: Dynamic background wallpaper
            // (Using a default high-quality placeholder image for now)
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1000',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Layer 2: Subtle dark overlay to ensure readability over bright wallpapers
            Container(color: Colors.black.withOpacity(0.15)),

            // Layer 3: The rest of the launcher UI (Clock, apps, bars)
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
