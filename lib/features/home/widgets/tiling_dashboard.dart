import 'package:flutter/material.dart';

class TilingDashboard extends StatelessWidget {
  final Map<String, int> usageStats;
  final int notificationCount;
  final int batteryLevel;
  final bool isCharging;

  const TilingDashboard({
    super.key,
    required this.usageStats,
    required this.notificationCount,
    required this.batteryLevel,
    required this.isCharging,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate total screen runtime telemetry
    final int totalMinutes = usageStats.values.fold(0, (sum, item) => sum + item);
    final String screenTimeDisplay = totalMinutes >= 60 
        ? '${(totalMinutes / 60).floor()}h ${totalMinutes % 60}m'
        : '${totalMinutes}m';

    // 2. Compute Focus Index algorithm matrix
    // Perfect score = 100%. Dips down based on screen time accumulation.
    int focusIndex = 100 - ((totalMinutes / 180) * 50).round(); 
    if (focusIndex > 100) focusIndex = 100;
    if (focusIndex < 0) focusIndex = 0;

    Color focusColor = Colors.cyanAccent.withOpacity(0.8);
    if (focusIndex < 75) focusColor = Colors.amberAccent.withOpacity(0.8);
    if (focusIndex < 45) focusColor = Colors.redAccent.withOpacity(0.8);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Column 1: Screen Time Telemetry
          Expanded(
            child: _buildTile(
              label: "SCREEN",
              val: screenTimeDisplay,
              color: totalMinutes >= 120 ? Colors.amberAccent.withOpacity(0.8) : Colors.white70,
            ),
          ),
          
          // Ultra-thin Tiling Divider 1
          Container(width: 1, height: 24, color: Colors.white.withOpacity(0.05)),

          // Column 2: Focus Index Dynamic Score
          Expanded(
            child: _buildTile(
              label: "FOCUS INDEX",
              val: "$focusIndex%",
              color: focusColor,
            ),
          ),

          // Ultra-thin Tiling Divider 2
          Container(width: 1, height: 24, color: Colors.white.withOpacity(0.05)),

          // Column 3: Battery Status
          Expanded(
            child: _buildTile(
              label: "ENERGY",
              val: isCharging ? "$batteryLevel% ⚡" : "$batteryLevel%",
              color: batteryLevel <= 20 ? Colors.redAccent.withOpacity(0.8) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({required String label, required String val, required Color color}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // <-- FIX COMPLETED HERE
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}