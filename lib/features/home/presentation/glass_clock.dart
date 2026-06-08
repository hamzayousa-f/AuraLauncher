import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/glass_theme.dart';

class GlassClock extends StatefulWidget {
  const GlassClock({super.key});

  @override
  State<GlassClock> createState() => _GlassClockState();
}

class _GlassClockState extends State<GlassClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 12-hour format for the large numeric display
    final String localTime = DateFormat('hh:mm').format(_now);
    final String localAmPm = DateFormat('a').format(_now); // Pulls AM or PM

    // Secondary Clock (e.g., UTC tracking)
    final String secondaryTime = DateFormat('hh:mm').format(_now.toUtc());
    final String secondaryAmPm = DateFormat('a').format(_now.toUtc());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildClockSquircleCard(
          locationCode: 'LHR',
          timeString: localTime,
          amPmString: localAmPm,
          offsetString: 'Local',
          isPrimary: true,
        ),
        const SizedBox(width: 16),
        _buildClockSquircleCard(
          locationCode: 'UTC',
          timeString: secondaryTime,
          amPmString: secondaryAmPm,
          offsetString: '-5h',
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildClockSquircleCard({
    required String locationCode,
    required String timeString,
    required String amPmString,
    required String offsetString,
    required bool isPrimary,
  }) {
    return GlassTheme.buildGlassPanel(
      borderRadius: BorderRadius.circular(
        32,
      ), // Slightly rounder, punchier squircles
      padding: EdgeInsets.zero,
      child: Container(
        width: 160, // Scaled up width from 150 to accommodate larger text
        height: 160, // Scaled up height from 150
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: isPrimary ? Colors.white.withOpacity(0.05) : Colors.black45,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Location Code
            Text(
              locationCode,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                decoration: TextDecoration.none,
              ),
            ),

            // Bold, Main Time Block with AM/PM Label underneath
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42, // Enlarged size
                    fontWeight: FontWeight.w700, // Punchy Bold text weight
                    letterSpacing: -1.0,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  amPmString,
                  style: TextStyle(
                    color: isPrimary
                        ? Colors.cyanAccent.withOpacity(0.8)
                        : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),

            // Bottom Offset Status
            Text(
              offsetString,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
