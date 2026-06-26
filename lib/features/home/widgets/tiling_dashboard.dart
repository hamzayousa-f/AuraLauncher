import 'package:flutter/material.dart';

class TilingDashboard extends StatelessWidget {
  final Map<String, int> usageStats;
  final int totalSystemMinutes;
  final int notificationCount;
  final int batteryLevel;
  final bool isCharging;

  const TilingDashboard({
    super.key,
    required this.usageStats,
    required this.totalSystemMinutes,
    required this.notificationCount,
    required this.batteryLevel,
    required this.isCharging,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Fall back to calculating totals from the usageStats map if totalSystemMinutes 
    // arrives as 0 during the initial frame load sync. This binds the layout directly to both pipelines.
    int finalMinutes = totalSystemMinutes;
    if (finalMinutes == 0 && usageStats.isNotEmpty) {
      finalMinutes = usageStats.values.fold(0, (sum, item) => sum + item);
    }

    final String screenTimeDisplay = finalMinutes >= 60 
        ? '${(finalMinutes / 60).floor()}h ${finalMinutes % 60}m'
        : '${finalMinutes}m';

    int focusIndex = 100 - ((finalMinutes / 120) * 10).round();
    focusIndex = focusIndex.clamp(0, 100);

    Color focusColor = Colors.cyanAccent.withOpacity(0.8);
    if (focusIndex < 85) focusColor = Colors.amberAccent.withOpacity(0.8);
    if (focusIndex < 60) focusColor = Colors.redAccent.withOpacity(0.8);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTile(
              label: "SCREEN",
              val: screenTimeDisplay,
              color: finalMinutes >= 150 ? Colors.amberAccent.withOpacity(0.8) : Colors.white70,
            ),
          ),
          Container(width: 1, height: 24, color: Colors.white.withOpacity(0.05)),
          Expanded(
            child: _buildTile(
              label: "FOCUS INDEX",
              val: "$focusIndex%",
              color: focusColor,
            ),
          ),
          Container(width: 1, height: 24, color: Colors.white.withOpacity(0.05)),
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
      mainAxisAlignment: MainAxisAlignment.center,
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