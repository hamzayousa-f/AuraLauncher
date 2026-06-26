import 'dart:math';
import 'package:flutter/material.dart';

class AuraWeeklyBarData {
  final String dayLabel;
  final double totalHours;
  final bool isToday;
  AuraWeeklyBarData({required this.dayLabel, required this.totalHours, this.isToday = false});
}

class AnalyticsView extends StatelessWidget {
  final VoidCallback onRefresh;
  
  const AnalyticsView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // Simulated weekly stats window
    final List<AuraWeeklyBarData> weeklyHistory = [
      AuraWeeklyBarData(dayLabel: 'Mon', totalHours: 4.2),
      AuraWeeklyBarData(dayLabel: 'Tue', totalHours: 3.8),
      AuraWeeklyBarData(dayLabel: 'Wed', totalHours: 5.1),
      AuraWeeklyBarData(dayLabel: 'Thu', totalHours: 2.9),
      AuraWeeklyBarData(dayLabel: 'Fri', totalHours: 3.7, isToday: true),
      AuraWeeklyBarData(dayLabel: 'Sat', totalHours: 1.5),
      AuraWeeklyBarData(dayLabel: 'Sun', totalHours: 0.8),
    ];

    double maxWeeklyVal = weeklyHistory.map((e) => e.totalHours).reduce(max);
    if (maxWeeklyVal == 0) maxWeeklyVal = 1.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 110.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Performance Matrix',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: -0.6),
          ),
          const SizedBox(height: 20),

          _buildGlassPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WEEKLY EVOLUTION',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                    ),
                    const Text(
                      'Avg: 3.1h/day',
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(weeklyHistory.length, (idx) {
                    final day = weeklyHistory[idx];
                    final double normalizedHeight = (day.totalHours / maxWeeklyVal) * 110;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${day.totalHours}h',
                          style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9, color: day.isToday ? Colors.cyanAccent : Colors.white24),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 14,
                          height: max(normalizedHeight, 4.0),
                          decoration: BoxDecoration(
                            color: day.isToday ? Colors.cyanAccent.withOpacity(0.8) : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: day.isToday ? Colors.cyanAccent : Colors.white.withOpacity(0.02),
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day.dayLabel,
                          style: TextStyle(fontSize: 10, color: day.isToday ? Colors.white : Colors.white38, fontWeight: day.isToday ? FontWeight.w600 : FontWeight.w400),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Focus Index Velocity'),
          _buildGlassPanel(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildMetricBlock(label: 'EFFICIENCY', value: '88%', trendColor: Colors.amberAccent),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
                _buildMetricBlock(label: 'SHIELD MARGIN', value: '-14%', trendColor: Colors.amberAccent),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
                _buildMetricBlock(label: 'DOPAMINE RELIEF', value: '+22m', trendColor: Colors.cyanAccent),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Subsystem Allocation Insights'),
          _buildGlassPanel(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Your focus distribution climbed 12% compared to last week. Peak terminal usage remains active around Friday afternoon routines.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBlock({required String label, required String value, required Color trendColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 18, color: trendColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.4)),
      ),
    );
  }

  Widget _buildGlassPanel({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}