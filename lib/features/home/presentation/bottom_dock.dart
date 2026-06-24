import 'package:flutter/material.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/shared/tactile_button.dart';

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
    return GlassTheme.buildGlassPanel(
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Dialer Action Target
          TactileButton(
            onTap: onPhoneTap,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(
                Icons.phone_enabled_rounded,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ),
          
          // 2. Central Unified Search Pill
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TactileButton(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Colors.white.withOpacity(0.35),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search apps...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Communications Hook (WhatsApp)
          TactileButton(
            onTap: onWhatsAppTap,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}