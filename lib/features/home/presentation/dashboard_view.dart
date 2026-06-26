import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/shared/tactile_button.dart';
import '../../../../core/services/usage_service.dart';

// --- Local Shared Configuration Models ---
class AuraPieSegment {
  final String label;
  final Duration duration;
  final Color color;
  AuraPieSegment({required this.label, required this.duration, required this.color});
}

class AuraCategorySummary {
  final String name;
  final Duration duration;
  final double percentage;
  AuraCategorySummary({required this.name, required this.duration, required this.percentage});
}

class AuraTopAppItem {
  final String name;
  final Duration duration;
  final String percentage;
  final IconData fallbackIcon;
  final Color markerColor;
  AuraTopAppItem({required this.name, required this.duration, required this.percentage, required this.fallbackIcon, required this.markerColor});
}

// --- Main State Controller Widget ---
class AuraDashboardView extends StatefulWidget {
  const AuraDashboardView({super.key});

  @override
  State<AuraDashboardView> createState() => _AuraDashboardViewState();
}

class _AuraDashboardViewState extends State<AuraDashboardView> {
  int _activeTabIndex = 0; // 0 = Hub, 1 = Analytics, 2 = Blocker
  bool _isLoading = true;
  
  Duration _totalScreentime = Duration.zero;
  List<AuraPieSegment> _segments = [];
  List<AuraCategorySummary> _categories = [];
  List<AuraTopAppItem> _topApps = [];

  final List<Color> _auraPalette = [
    const Color(0xFF818CF8), // Indigo
    const Color(0xFF60A5FA), // Soft Blue
    const Color(0xFF34D399), // Mint Green
    const Color(0xFFFBBF24), // Amber
  ];

  @override
  void initState() {
    super.initState();
    _fetchRealTelemetry();
  }

  Future<void> _fetchRealTelemetry() async {
    setState(() => _isLoading = true);
    final Map<String, int> rawStats = await UsageService.getZenithUsageData();

    if (rawStats.isEmpty) {
      setState(() {
        _totalScreentime = Duration.zero;
        _segments = [];
        _categories = [];
        _topApps = [];
        _isLoading = false;
      });
      return;
    }

    // Strict structural sync to ensure dashboard maps match tiling panels 1:1
    int calculatedTotalMinutes = rawStats.values.fold(0, (sum, mins) => sum + mins);
    _totalScreentime = Duration(minutes: calculatedTotalMinutes);

    final List<MapEntry<String, int>> sortedApps = rawStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<AuraTopAppItem> processedApps = [];
    final List<AuraPieSegment> processedSegments = [];
    int itemsToTake = min(sortedApps.length, 4);
    int dynamicMinutesSum = 0;

    for (int i = 0; i < sortedApps.length; i++) {
      final entry = sortedApps[i];
      final String readableName = _parsePackageToAppName(entry.key);
      final Duration appDuration = Duration(minutes: entry.value);
      final double appPercent = calculatedTotalMinutes > 0 ? (entry.value / calculatedTotalMinutes) * 100 : 0;

      if (i < itemsToTake) {
        dynamicMinutesSum += entry.value;
        final Color assignedColor = _auraPalette[i % _auraPalette.length];

        processedApps.add(
          AuraTopAppItem(
            name: readableName,
            duration: appDuration,
            percentage: '${appPercent.toStringAsFixed(0)}%',
            fallbackIcon: _getCategoryIcon(entry.key),
            markerColor: assignedColor,
          ),
        );

        processedSegments.add(
          AuraPieSegment(
            label: readableName,
            duration: appDuration,
            color: assignedColor,
          ),
        );
      }
    }

    // Safely dump any remaining fractional apps to maintain data balance 1:1
    if (calculatedTotalMinutes > dynamicMinutesSum) {
      processedSegments.add(
        AuraPieSegment(
          label: 'Others',
          duration: Duration(minutes: calculatedTotalMinutes - dynamicMinutesSum),
          color: Colors.white.withOpacity(0.06),
        ),
      );
    }

    // Process Live Category Matrix with fixed bool evaluation
    final Map<String, int> categoryAggregator = {
      'Social Media': 0,
      'Productivity': 0,
      'Entertainment': 0,
      'Utilities': 0,
    };

    rawStats.forEach((pkg, mins) {
      final String lowerPkg = pkg.toLowerCase();
      if (lowerPkg.contains('instagram') || 
          lowerPkg.contains('facebook') || 
          lowerPkg.contains('twitter') || 
          lowerPkg.contains('snapchat') || 
          lowerPkg.contains('tiktok') || 
          lowerPkg.contains('whatsapp')) {
        categoryAggregator['Social Media'] = categoryAggregator['Social Media']! + mins;
      } else if (lowerPkg.contains('youtube') || 
                 lowerPkg.contains('netflix') || 
                 lowerPkg.contains('game') || 
                 lowerPkg.contains('vlc') || 
                 lowerPkg.contains('spotify')) {
        categoryAggregator['Entertainment'] = categoryAggregator['Entertainment']! + mins;
      } else if (lowerPkg.contains('studio') || 
                 lowerPkg.contains('github') || 
                 lowerPkg.contains('flutter') || 
                 lowerPkg.contains('teams') || 
                 lowerPkg.contains('slack') || 
                 lowerPkg.contains('zoom') || 
                 lowerPkg.contains('vcode')) {
        categoryAggregator['Productivity'] = categoryAggregator['Productivity']! + mins;
      } else {
        categoryAggregator['Utilities'] = categoryAggregator['Utilities']! + mins;
      }
    });

    final List<AuraCategorySummary> processedCategories = [];
    categoryAggregator.forEach((catName, mins) {
      if (mins > 0) {
        processedCategories.add(
          AuraCategorySummary(
            name: catName,
            duration: Duration(minutes: mins),
            percentage: calculatedTotalMinutes > 0 ? mins / calculatedTotalMinutes : 0,
          ),
        );
      }
    });
    processedCategories.sort((a, b) => b.duration.compareTo(a.duration));

    setState(() {
      _topApps = processedApps;
      _segments = processedSegments;
      _categories = processedCategories;
      _isLoading = false;
    });
  }

  String _parsePackageToAppName(String packageName) {
    if (!packageName.contains('.')) return packageName;
    final parts = packageName.split('.');
    String name = parts.last;
    if (name.toLowerCase() == 'android' && parts.length > 1) {
      name = parts[parts.length - 2];
    }
    return name[0].toUpperCase() + name.substring(1);
  }

  IconData _getCategoryIcon(String pkg) {
    final lower = pkg.toLowerCase();
    if (lower.contains('camera') || lower.contains('gallery') || lower.contains('instagram')) return Icons.camera_alt_rounded;
    if (lower.contains('code') || lower.contains('github') || lower.contains('studio')) return Icons.code_rounded;
    if (lower.contains('youtube') || lower.contains('play') || lower.contains('video')) return Icons.play_circle_fill_rounded;
    return Icons.widgets_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, 
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                      ),
                    ),
                  )
                : IndexedStack(
                    index: _activeTabIndex,
                    children: [
                      _buildDailyHubView(),
                      _buildPlaceholderView('Analytics Engine Pipeline Active'),
                      _buildPlaceholderView('System Shield Blocker Ready'),
                    ],
                  ),
          ),
          
          // Floating Ambient Bottom Glass Dock Wrapper
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom > 0 
                ? MediaQuery.of(context).padding.bottom 
                : 24,
            child: _buildFloatingGlassDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHubView() {
    final int hours = _totalScreentime.inHours;
    final int mins = _totalScreentime.inMinutes.remainder(60);

    return RefreshIndicator(
      onRefresh: _fetchRealTelemetry,
      color: Colors.white,
      backgroundColor: Colors.black54,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 110.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TactileButton(
                  onTap: () => Navigator.of(context).pop(),
                  child: _buildGlassIcon(Icons.arrow_back_ios_new_rounded),
                ),
                const Text(
                  'AURA ENGINE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
                TactileButton(
                  onTap: _fetchRealTelemetry,
                  child: _buildGlassIcon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Digital Footprint',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 20),
            
            // 1st Component: Synced Vector Pie Chart Card
            _buildGlassPanel(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: AuraDashboardPiePainter(
                          segments: _segments,
                          totalMinutes: _totalScreentime.inMinutes.toDouble(),
                          trackColor: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${hours}h ${mins}m',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TOTAL SCREEN TIME',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2nd Component: Category Breakdowns
            if (_categories.isNotEmpty) ...[
              _buildSectionHeader('Category Matrix'),
              _buildGlassPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: List.generate(_categories.length, (idx) {
                    final cat = _categories[idx];
                    return Padding(
                      padding: EdgeInsets.only(bottom: idx == _categories.length - 1 ? 0 : 16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cat.name,
                                style: const TextStyle(fontSize: 13, color: Colors.white),
                              ),
                              Text(
                                '${cat.duration.inHours > 0 ? "${cat.duration.inHours}h " : ""}${cat.duration.inMinutes.remainder(60)}m',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: cat.percentage,
                              backgroundColor: Colors.white.withOpacity(0.04),
                              color: _auraPalette[idx % _auraPalette.length].withOpacity(0.8),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 3rd Component: Top Consumer Channels
            _buildSectionHeader('Top Consumer Channels'),
            if (_topApps.isEmpty)
              _buildGlassPanel(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No background logs found.',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                  ),
                ),
              )
            else
              ...List.generate(_topApps.length, (idx) {
                final app = _topApps[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildGlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(app.fallbackIcon, color: app.markerColor, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            app.name,
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${app.duration.inHours > 0 ? "${app.duration.inHours}h " : ""}${app.duration.inMinutes.remainder(60)}m',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                          Text(
                            app.percentage,
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderView(String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGlassPanel(
            padding: const EdgeInsets.all(32),
            child: SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bubble_chart_rounded, size: 32, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, letterSpacing: -0.1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingGlassDock() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDockItem(index: 0, icon: Icons.fullscreen_rounded, label: 'Dashboard'),
              _buildDockItem(index: 1, icon: Icons.insights_rounded, label: 'Analytics'),
              _buildDockItem(index: 2, icon: Icons.block_flipped, label: 'Blocker'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({required int index, required IconData icon, required String label}) {
    final bool isSelected = _activeTabIndex == index;
    return TactileButton(
      onTap: () => setState(() => _activeTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white38,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
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

  Widget _buildGlassIcon(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Icon(icon, color: Colors.white70, size: 16),
        ),
      ),
    );
  }

  Widget _buildGlassPanel({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuraDashboardPiePainter extends CustomPainter {
  final List<AuraPieSegment> segments;
  final double totalMinutes;
  final Color trackColor;

  AuraDashboardPiePainter({required this.segments, required this.totalMinutes, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 14.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;
    final Rect boundingSquare = Rect.fromCircle(center: center, radius: radius);

    final Paint paintTrack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;

    canvas.drawCircle(center, radius, paintTrack);

    if (totalMinutes <= 0 || segments.isEmpty) return;

    final Paint paintSegment = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double currentStartAngle = -pi / 2;
    const double angularGap = 0.07;

    for (var segment in segments) {
      final double segmentMins = segment.duration.inMinutes.toDouble();
      if (segmentMins <= 0) continue;

      final double sweepAngle = (segmentMins / totalMinutes) * 2 * pi;
      double adjustedSweep = sweepAngle - angularGap;
      if (adjustedSweep < 0.02) adjustedSweep = 0.02;

      paintSegment.color = segment.color;
      canvas.drawArc(boundingSquare, currentStartAngle + (angularGap / 2), adjustedSweep, false, paintSegment);
      currentStartAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant AuraDashboardPiePainter oldDelegate) {
    return oldDelegate.totalMinutes != totalMinutes || oldDelegate.segments.length != segments.length;
  }
}