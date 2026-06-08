import 'package:flutter/material.dart';
import '../../../core/theme/glass_theme.dart';

class BottomDock extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onPhoneTap;
  final VoidCallback onWhatsAppTap;

  const BottomDock({
    super.key,
    required this.onSearchTap,
    required this.onPhoneTap,
    required this.onWhatsAppTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bottom Left Corner: Phone App Shortcut
        GestureDetector(
          onTap: onPhoneTap,
          child: GlassTheme.buildGlassPanel(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(50), // Circular glass button
            child: const Icon(
              Icons.phone_android_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Center: Expanded Minimalist Glass Search Bar
        Expanded(
          child: GestureDetector(
            onTap: onSearchTap,
            child: GlassTheme.buildGlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search apps...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Bottom Right Corner: WhatsApp Shortcut
        GestureDetector(
          onTap: onWhatsAppTap,
          child: GlassTheme.buildGlassPanel(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(50), // Circular glass button
            child: const Icon(
              Icons.chat_bubble_outline_rounded, // Stand-in icon for WhatsApp
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}
