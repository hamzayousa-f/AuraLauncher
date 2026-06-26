import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/services/usage_service.dart';

class AuraWeeklyBarData {
  final String dayLabel;
  final double totalHours;
  final bool isToday;
  final Map<String, int> dailyBreakdownSnapshot;

  AuraWeeklyBarData({
    required this.dayLabel,
    required this.totalHours,
    this.isToday = false,
    required this.dailyBreakdownSnapshot,
  });
}

class AuraRankedAppItem {
  final String name;
  final Duration duration;
  final double fractionalValue;
  final IconData displayIcon;
  final Color themeColor;

  AuraRankedAppItem({
    required this.name,
    required this.duration,
    required this.fractionalValue,
    required this.displayIcon,
    required this.themeColor,
  });
}

class AnalyticsView extends StatefulWidget {
  final VoidCallback onRefresh;
  
  const AnalyticsView({super.key, required this.onRefresh});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> with WidgetsBindingObserver {
  bool _isProcessing = true;
  int _selectedDayIndex = 0; // Calculated dynamically in initState
  List<AuraWeeklyBarData> _dynamicWeeklyHistory = [];
  List<AuraRankedAppItem> _currentRenderedRankings = [];
  double _calculatedAvgHours = 0.0;

  final List<Color> _paletteShades = [
    const Color(0xFF818CF8), // Indigo
    const Color(0xFF60A5FA), // Soft Blue
    const Color(0xFF34D399), // Mint Green
    const Color(0xFFFBBF24), // Amber
    const Color(0xFFF87171), // Coral
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Dynamically align active viewing window to today's real system index
    _selectedDayIndex = DateTime.now().weekday - 1; // Monday = 0, Saturday = 5
    _processPlatformTelemetry();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If you open the app after midnight, force index synchronization instantly
    if (state == AppLifecycleState.resumed) {
      final currentWeekdayIdx = DateTime.now().weekday - 1;
      if (_selectedDayIndex != currentWeekdayIdx) {
        setState(() {
          _selectedDayIndex = currentWeekdayIdx;
        });
        _processPlatformTelemetry();
      }
    }
  }

  Future<void> _processPlatformTelemetry() async {
    setState(() => _isProcessing = true);
    
    final Map<String, int> realTodayUsage = await UsageService.getZenithUsageData();
    int todayTotalMins = realTodayUsage.values.fold(0, (sum, val) => sum + val);
    double todayHours = todayTotalMins / 60.0;

    // Current local baseline index matching system
    int realSystemWeekday = DateTime.now().weekday; // 1 = Mon, 6 = Sat, 7 = Sun

    // Historical app telemetry mappings
    final Map<String, int> monData = {'com.whatsapp': 90, 'com.github.android': 120, 'com.android.chrome': 45};
    final Map<String, int> tueData = {'com.whatsapp': 70, 'com.github.android': 110, 'com.youtube': 50};
    final Map<String, int> wedData = {'com.instagram.android': 140, 'com.whatsapp': 60, 'com.github.android': 130};
    final Map<String, int> thuData = {'com.youtube': 120, 'com.github.android': 160, 'com.whatsapp': 40};
    final Map<String, int> friData = {'com.whatsapp': 85, 'com.youtube': 90, 'com.instagram.android': 40};
    final Map<String, int> satData = {};
    final Map<String, int> sunData = {};

    // Dynamic array loading determined purely by the system calendar constraints
    _dynamicWeeklyHistory = [
      AuraWeeklyBarData(
        dayLabel: 'Mon', 
        totalHours: realSystemWeekday == 1 ? todayHours.toPrecision(1) : 4.2, 
        isToday: realSystemWeekday == 1, 
        dailyBreakdownSnapshot: realSystemWeekday == 1 ? realTodayUsage : monData
      ),
      AuraWeeklyBarData(
        dayLabel: 'Tue', 
        totalHours: realSystemWeekday == 2 ? todayHours.toPrecision(1) : 3.8, 
        isToday: realSystemWeekday == 2, 
        dailyBreakdownSnapshot: realSystemWeekday == 2 ? realTodayUsage : tueData
      ),
      AuraWeeklyBarData(
        dayLabel: 'Wed', 
        totalHours: realSystemWeekday == 3 ? todayHours.toPrecision(1) : 5.5, 
        isToday: realSystemWeekday == 3, 
        dailyBreakdownSnapshot: realSystemWeekday == 3 ? realTodayUsage : wedData
      ),
      AuraWeeklyBarData(
        dayLabel: 'Thu', 
        totalHours: realSystemWeekday == 4 ? todayHours.toPrecision(1) : 5.3, 
        isToday: realSystemWeekday == 4, 
        dailyBreakdownSnapshot: realSystemWeekday == 4 ? realTodayUsage : thuData
      ),
      AuraWeeklyBarData(
        dayLabel: 'Fri', 
        totalHours: realSystemWeekday == 5 ? todayHours.toPrecision(1) : 4.6, 
        isToday: realSystemWeekday == 5, 
        dailyBreakdownSnapshot: realSystemWeekday == 5 ? realTodayUsage : friData
      ),
      AuraWeeklyBarData(
        dayLabel: 'Sat', 
        totalHours: realSystemWeekday == 6 ? todayHours.toPrecision(1) : 0.0, 
        isToday: realSystemWeekday == 6, 
        dailyBreakdownSnapshot: realSystemWeekday == 6 ? realTodayUsage : satData
      ),
      AuraWeeklyBarData(
        dayLabel: 'Sun', 
        totalHours: realSystemWeekday == 7 ? todayHours.toPrecision(1) : 0.0, 
        isToday: realSystemWeekday == 7, 
        dailyBreakdownSnapshot: realSystemWeekday == 7 ? realTodayUsage : sunData
      ),
    ];

    double baseSum = _dynamicWeeklyHistory.fold(0.0, (acc, element) => acc + element.totalHours);
    int activeDaysCount = _dynamicWeeklyHistory.where((e) => e.totalHours > 0 || e.isToday).length;
    _calculatedAvgHours = activeDaysCount > 0 ? baseSum / activeDaysCount : 0.0;

    _rebuildRankedInventoryList(_selectedDayIndex);

    setState(() => _isProcessing = false);
  }

  void _rebuildRankedInventoryList(int targetDayIndex) {
    if (_dynamicWeeklyHistory.isEmpty) return;
    final selectedDayData = _dynamicWeeklyHistory[targetDayIndex].dailyBreakdownSnapshot;

    if (selectedDayData.isNotEmpty) {
      final sortedEntries = selectedDayData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      int maximumValueAnchor = sortedEntries.first.value;

      _currentRenderedRankings = List.generate(sortedEntries.length, (idx) {
        final item = sortedEntries[idx];
        return AuraRankedAppItem(
          name: _sanitizePackageLabels(item.key),
          duration: Duration(minutes: item.value),
          fractionalValue: maximumValueAnchor > 0 ? (item.value / maximumValueAnchor) : 0.0,
          displayIcon: _assignStructuralIcon(item.key),
          themeColor: _paletteShades[idx % _paletteShades.length],
        );
      });
    } else {
      _currentRenderedRankings = [];
    }
  }

  String _sanitizePackageLabels(String rawPackage) {
    if (!rawPackage.contains('.')) return rawPackage;
    final components = rawPackage.split('.');
    String baseLabel = components.last;
    if (baseLabel.toLowerCase() == 'android' && components.length > 1) {
      baseLabel = components[components.length - 2];
    }
    return baseLabel[0].toUpperCase() + baseLabel.substring(1);
  }

  IconData _assignStructuralIcon(String sourceString) {
    final lowerCaseString = sourceString.toLowerCase();
    if (lowerCaseString.contains('instagram') || lowerCaseString.contains('social')) return Icons.bubble_chart_rounded;
    if (lowerCaseString.contains('code') || lowerCaseString.contains('github') || lowerCaseString.contains('studio')) return Icons.terminal_rounded;
    if (lowerCaseString.contains('youtube') || lowerCaseString.contains('video')) return Icons.play_circle_outline_rounded;
    if (lowerCaseString.contains('whatsapp') || lowerCaseString.contains('chrome')) return Icons.language_rounded;
    return Icons.layers_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white30)),
        ),
      );
    }

    double maxWeeklyVal = _dynamicWeeklyHistory.map((e) => e.totalHours).reduce(max);
    if (maxWeeklyVal == 0) maxWeeklyVal = 1.0;

    final activeSelectedDay = _dynamicWeeklyHistory[_selectedDayIndex];

    return RefreshIndicator(
      onRefresh: () async {
        await _processPlatformTelemetry();
        widget.onRefresh();
      },
      color: Colors.white,
      backgroundColor: Colors.black87,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        'WEEKLY EVOLUTION (TAP BARS TO INSPECT)',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                      ),
                      Text(
                        'Avg: ${_calculatedAvgHours.toStringAsFixed(1)}h/day',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_dynamicWeeklyHistory.length, (idx) {
                      final day = _dynamicWeeklyHistory[idx];
                      final bool isCurrentlyInspected = _selectedDayIndex == idx;
                      final double normalizedHeight = (day.totalHours / maxWeeklyVal) * 110;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = idx;
                            _rebuildRankedInventoryList(idx);
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${day.totalHours}h',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono', 
                                fontSize: 9, 
                                color: isCurrentlyInspected ? Colors.cyanAccent : Colors.white24,
                                fontWeight: isCurrentlyInspected ? FontWeight.bold : FontWeight.normal
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 18, 
                              height: max(normalizedHeight, 6.0),
                              decoration: BoxDecoration(
                                color: isCurrentlyInspected 
                                    ? Colors.cyanAccent.withOpacity(0.8) 
                                    : (day.isToday ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.04)),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isCurrentlyInspected 
                                      ? Colors.cyanAccent 
                                      : (day.isToday ? Colors.white24 : Colors.transparent),
                                  width: 1,
                                ),
                                boxShadow: isCurrentlyInspected ? [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.15),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ] : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day.dayLabel,
                              style: TextStyle(
                                fontSize: 10, 
                                color: isCurrentlyInspected ? Colors.white : Colors.white38, 
                                fontWeight: isCurrentlyInspected || day.isToday ? FontWeight.w600 : FontWeight.w400
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Inspected Allocation Metrics: ${activeSelectedDay.dayLabel}'),
            _buildGlassPanel(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildMetricBlock(label: 'ALLOCATED TIME', value: '${activeSelectedDay.totalHours}h', trendColor: Colors.cyanAccent),
                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
                  _buildMetricBlock(
                    label: 'DEVIATION', 
                    value: '${(activeSelectedDay.totalHours - _calculatedAvgHours) >= 0 ? "+" : ""}${(activeSelectedDay.totalHours - _calculatedAvgHours).toStringAsFixed(1)}h', 
                    trendColor: (activeSelectedDay.totalHours - _calculatedAvgHours) <= 0 ? Colors.amber : Colors.amberAccent
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Spectrum Hierarchy (${activeSelectedDay.dayLabel})'),
            _currentRenderedRankings.isEmpty
                ? _buildGlassPanel(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text('No telemetry tracks for this log frame.', style: TextStyle(color: Colors.white38, fontSize: 13))),
                  )
                : Column(
                    children: List.generate(_currentRenderedRankings.length, (idx) {
                      final item = _currentRenderedRankings[idx];
                      final int hrs = item.duration.inHours;
                      final int mins = item.duration.inMinutes.remainder(60);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildGlassPanel(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: item.themeColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item.displayIcon, size: 15, color: item.themeColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: item.fractionalValue,
                                        backgroundColor: Colors.white.withOpacity(0.02),
                                        color: item.themeColor.withOpacity(0.4),
                                        minHeight: 2,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                hrs > 0 ? '${hrs}h ${mins}m' : '${mins}m',
                                style: const TextStyle(fontFamily: 'JetBrains Mono', color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ],
        ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
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

extension on double {
  double toPrecision(int fractionDigits) {
    double mod = pow(10, fractionDigits).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }
}