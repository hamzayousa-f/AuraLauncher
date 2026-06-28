import 'dart:math';
import 'dart:ui';
import 'package:aura/features/home/widgets/analytics_view.dart';
import 'package:aura/features/home/widgets/blocker_view.dart';
import 'package:flutter/material.dart';
import '../../../../core/shared/tactile_button.dart';
import '../../../../core/services/usage_service.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class AuraPieSegment {
  final String label;
  final Duration duration;
  final Color color;
  const AuraPieSegment({required this.label, required this.duration, required this.color});
}

class AuraCategorySummary {
  final String name;
  final Duration duration;
  final double percentage;
  const AuraCategorySummary({required this.name, required this.duration, required this.percentage});
}

class AuraTopAppItem {
  final String name;
  final Duration duration;
  final String percentage;
  final IconData fallbackIcon;
  final Color markerColor;
  const AuraTopAppItem({
    required this.name,
    required this.duration,
    required this.percentage,
    required this.fallbackIcon,
    required this.markerColor,
  });
}

// ─── Pre-computed constants ──────────────────────────────────────────────

const _kWhite02  = Color(0x05FFFFFF);
const _kWhite03  = Color(0x08FFFFFF);
const _kWhite04  = Color(0x0AFFFFFF);
const _kWhite05  = Color(0x0DFFFFFF);
const _kWhite06  = Color(0x0FFFFFFF);
const _kWhite30  = Color(0x4DFFFFFF);
const _kWhite38  = Color(0x61FFFFFF);
const _kWhite40  = Color(0x66FFFFFF);
const _kWhite70  = Color(0xB3FFFFFF);
const _kTrackColor = Color(0x0AFFFFFF);

const List<Color> _kAuraPalette = [
  Color(0xFF818CF8),
  Color(0xFF60A5FA),
  Color(0xFF34D399),
  Color(0xFFFBBF24),
];

// ─── Main widget ──────────────────────────────────────────────────────────────

class AuraDashboardView extends StatefulWidget {
  const AuraDashboardView({super.key});

  @override
  State<AuraDashboardView> createState() => _AuraDashboardViewState();
}

class _AuraDashboardViewState extends State<AuraDashboardView>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  double _currentPageOffset = 0.0;
  bool _isLoading = true;
  bool _transitionFinished = false;

  Duration _totalScreentime = Duration.zero;
  List<AuraPieSegment> _segments = const [];
  List<AuraCategorySummary> _categories = const [];
  List<AuraTopAppItem> _topApps = const [];

  late final AnimationController _backdropController;
  late final Animation<double> _backdropOpacity;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(_handlePageScrollMetrics);

    _backdropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _backdropOpacity = CurvedAnimation(
      parent: _backdropController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() => _transitionFinished = true);
        _backdropController.forward();
        _fetchRealTelemetry();
      }
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScrollMetrics);
    _pageController.dispose();
    _backdropController.dispose();
    super.dispose();
  }

  void _handlePageScrollMetrics() {
    if (_pageController.hasClients) {
      setState(() {
        _currentPageOffset = _pageController.page ?? 0.0;
      });
    }
  }

  Future<void> _fetchRealTelemetry() async {
    if (!mounted) return;
    
    final Map<String, int> rawStats = await UsageService.getZenithUsageData();
    if (!mounted) return;

    if (rawStats.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final int totalMinutes = rawStats.values.fold(0, (s, v) => s + v);
    final List<MapEntry<String, int>> sortedApps = rawStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final int itemsToTake = min(sortedApps.length, 4);
    int dynamicMinutesSum = 0;
    final List<AuraTopAppItem> processedApps = [];
    final List<AuraPieSegment> processedSegments = [];

    for (int i = 0; i < sortedApps.length; i++) {
      final entry = sortedApps[i];
      final String readableName = _parsePackageToAppName(entry.key);
      final Duration appDuration = Duration(minutes: entry.value);
      final double appPercent = totalMinutes > 0 ? (entry.value / totalMinutes) * 100 : 0;

      if (i < itemsToTake) {
        dynamicMinutesSum += entry.value;
        final Color assignedColor = _kAuraPalette[i % _kAuraPalette.length];
        processedApps.add(AuraTopAppItem(
          name: readableName,
          duration: appDuration,
          percentage: '${appPercent.toStringAsFixed(0)}%',
          fallbackIcon: _getCategoryIcon(entry.key),
          markerColor: assignedColor,
        ));
        processedSegments.add(AuraPieSegment(
          label: readableName,
          duration: appDuration,
          color: assignedColor,
        ));
      }
    }

    if (totalMinutes > dynamicMinutesSum) {
      processedSegments.add(AuraPieSegment(
        label: 'Others',
        duration: Duration(minutes: totalMinutes - dynamicMinutesSum),
        color: _kWhite06,
      ));
    }

    final Map<String, int> catMap = {'Social Media': 0, 'Productivity': 0, 'Entertainment': 0, 'Utilities': 0};
    for (final e in rawStats.entries) {
      final String p = e.key.toLowerCase();
      if (p.contains('instagram') || p.contains('facebook') || p.contains('twitter') || p.contains('whatsapp')) {
        catMap['Social Media'] = catMap['Social Media']! + e.value;
      } else if (p.contains('youtube') || p.contains('netflix') || p.contains('spotify')) {
        catMap['Entertainment'] = catMap['Entertainment']! + e.value;
      } else if (p.contains('studio') || p.contains('github') || p.contains('flutter')) {
        catMap['Productivity'] = catMap['Productivity']! + e.value;
      } else {
        catMap['Utilities'] = catMap['Utilities']! + e.value;
      }
    }

    final List<AuraCategorySummary> processedCategories = [
      for (final e in catMap.entries)
        if (e.value > 0)
          AuraCategorySummary(
            name: e.key,
            duration: Duration(minutes: e.value),
            percentage: totalMinutes > 0 ? e.value / totalMinutes : 0,
          ),
    ]..sort((a, b) => b.duration.compareTo(a.duration));

    setState(() {
      _totalScreentime = Duration(minutes: totalMinutes);
      _topApps = processedApps;
      _segments = processedSegments;
      _categories = processedCategories;
      _isLoading = false;
    });
  }

  String _parsePackageToAppName(String packageName) {
    if (!packageName.contains('.')) return packageName;
    final String name = packageName.split('.').last;
    return name[0].toUpperCase() + name.substring(1);
  }

  IconData _getCategoryIcon(String pkg) {
    final lower = pkg.toLowerCase();
    if (lower.contains('camera') || lower.contains('instagram')) return Icons.camera_alt_rounded;
    if (lower.contains('code') || lower.contains('studio')) return Icons.code_rounded;
    if (lower.contains('play') || lower.contains('video')) return Icons.play_circle_fill_rounded;
    return Icons.widgets_rounded;
  }

  void _onDockItemTap(int targetPageIndex) {
    _pageController.animateToPage(
      targetPageIndex,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (_transitionFinished)
            Positioned.fill(
              child: FadeTransition(
                opacity: _backdropOpacity,
                child: const _StaticBackdrop(),
              ),
            )
          else
            const Positioned.fill(child: ColoredBox(color: Colors.black54)),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _AuraTopAppBar(
                    onBack: () => Navigator.of(context).pop(),
                    onRefresh: _fetchRealTelemetry,
                  ),
                ),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 1, color: _kWhite30))
                    : PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _DailyHubView(
                            totalScreentime: _totalScreentime,
                            segments: _segments,
                            categories: _categories,
                            topApps: _topApps,
                            palette: _kAuraPalette,
                            onRefresh: _fetchRealTelemetry,
                          ),
                          AnalyticsView(onRefresh: _fetchRealTelemetry),
                          const Material(color: Colors.transparent, child: BlockerView()),
                        ],
                      ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom > 0 
                ? MediaQuery.of(context).padding.bottom 
                : 24,
            child: RepaintBoundary(
              child: _FloatingGlassDock(
                pageOffset: _currentPageOffset,
                onTap: _onDockItemTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Static backdrop ──────────────────────────────────────────────────────────

class _StaticBackdrop extends StatelessWidget {
  const _StaticBackdrop();
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: const ColoredBox(color: Color(0x66000000)),
      ),
    );
  }
}

// ─── Components (Rest of the UI Optimized) ────────────────────────────────────

class _AuraTopAppBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  const _AuraTopAppBar({required this.onBack, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TactileButton(onTap: onBack, child: const _GlassIcon(Icons.arrow_back_ios_new_rounded)),
        const Text('AURA CORE ENGINE', style: TextStyle(color: _kWhite38, fontSize: 10, letterSpacing: 2)),
        TactileButton(onTap: onRefresh, child: const _GlassIcon(Icons.refresh_rounded)),
      ],
    );
  }
}

class _DailyHubView extends StatelessWidget {
  final Duration totalScreentime;
  final List<AuraPieSegment> segments;
  final List<AuraCategorySummary> categories;
  final List<AuraTopAppItem> topApps;
  final List<Color> palette;
  final Future<void> Function() onRefresh;

  const _DailyHubView({
    required this.totalScreentime,
    required this.segments,
    required this.categories,
    required this.topApps,
    required this.palette,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final int h = totalScreentime.inHours;
    final int m = totalScreentime.inMinutes.remainder(60);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.white,
      backgroundColor: Colors.black,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digital Footprint', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
            const SizedBox(height: 20),
            
            _GlassPanel(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: AuraDashboardPiePainter(
                            segments: segments,
                            totalMinutes: totalScreentime.inMinutes.toDouble(),
                            trackColor: _kTrackColor,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$h\h $m\m', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('TOTAL TIME', style: TextStyle(color: _kWhite30, fontSize: 8, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (categories.isNotEmpty) ...[
              const _SectionHeader('Category Matrix'),
              _GlassPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: List.generate(categories.length, (i) => Padding(
                    padding: EdgeInsets.only(bottom: i == categories.length - 1 ? 0 : 16),
                    child: _CategoryRow(category: categories[i], color: palette[i % palette.length]),
                  )),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _SectionHeader('Top Channels'),
            _TopAppsSection(topApps: topApps),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final AuraCategorySummary category;
  final Color color;
  const _CategoryRow({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category.name, style: const TextStyle(fontSize: 12, color: Colors.white)),
            Text('${category.duration.inMinutes}m', style: const TextStyle(fontSize: 12, color: _kWhite40)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: category.percentage,
            backgroundColor: _kWhite04,
            valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _TopAppsSection extends StatelessWidget {
  final List<AuraTopAppItem> topApps;
  const _TopAppsSection({required this.topApps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(topApps.length, (idx) {
        final app = topApps[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(app.fallbackIcon, color: app.markerColor, size: 18),
                const SizedBox(width: 14),
                Expanded(child: Text(app.name, style: const TextStyle(fontSize: 14, color: Colors.white))),
                Text(app.percentage, style: const TextStyle(color: _kWhite30, fontSize: 11)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Refactored Sliding Dock Framework ──────────────────────────────────────────

// ─── Refactored Sliding Dock Framework ──────────────────────────────────────────

class _FloatingGlassDock extends StatelessWidget {
  final double pageOffset;
  final ValueChanged<int> onTap;
  
  const _FloatingGlassDock({required this.pageOffset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Round to the closest tab index to lock the underlying structural track position
    final int roundedTargetIndex = pageOffset.round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 68, // Stable concrete physical container bounding height
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0x0CFFFFFF), // Slightly enhanced contrast base
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x12FFFFFF), width: 1.2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double elementWidth = totalWidth / 3;

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Smooth underlying highlight slider track block
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: roundedTargetIndex * elementWidth,
                    width: elementWidth,
                    top: 6,
                    bottom: 6,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Text items and icons alignment template array
                  Row(
                    children: [
                      Expanded(
                        child: _DockItem(
                          icon: Icons.fullscreen_rounded, 
                          label: 'Dashboard', 
                          matchingPageIndex: 0,
                          currentPageOffset: pageOffset,
                          onTap: () => onTap(0),
                        ),
                      ),
                      Expanded(
                        child: _DockItem(
                          icon: Icons.insights_rounded, 
                          label: 'Analytics', 
                          matchingPageIndex: 1,
                          currentPageOffset: pageOffset,
                          onTap: () => onTap(1),
                        ),
                      ),
                      Expanded(
                        child: _DockItem(
                          icon: Icons.block_flipped, 
                          label: 'Blocker', 
                          matchingPageIndex: 2,
                          currentPageOffset: pageOffset,
                          onTap: () => onTap(2),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int matchingPageIndex;
  final double currentPageOffset;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon, 
    required this.label, 
    required this.matchingPageIndex,
    required this.currentPageOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic continuous text-color interpolation matching calculations
    final double distanceToOffset = (currentPageOffset - matchingPageIndex).abs();
    final double activationRatio = (1.0 - distanceToOffset).clamp(0.0, 1.0);

    final Color itemActiveColor = Color.lerp(
      const Color(0x61FFFFFF), // Subtle unselected white
      Colors.white,             // Vibrant active white
      activationRatio,
    )!;

    return TactileButton(
      onTap: onTap,
      child: SizedBox(
        height: double.infinity, // Expand layout bounds to absorb touch inputs cleanly
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: itemActiveColor, 
              size: 21,
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                color: itemActiveColor, 
                fontSize: 10,
                fontWeight: activationRatio > 0.5 ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── UI Utility Components ────────────────────────────────────────────────────

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassPanel({required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: _kWhite02, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kWhite05)),
      child: child,
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  const _GlassIcon(this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: _kWhite04, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kWhite06)),
      child: Icon(icon, color: _kWhite70, size: 16),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 12, color: _kWhite40)),
    );
  }
}

class AuraDashboardPiePainter extends CustomPainter {
  final List<AuraPieSegment> segments;
  final double totalMinutes;
  final Color trackColor;
  const AuraDashboardPiePainter({required this.segments, required this.totalMinutes, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..isAntiAlias = true;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - 14) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, paint..color = trackColor);

    if (totalMinutes <= 0) return;

    double startAngle = -pi / 2;
    for (final seg in segments) {
      final sweep = (seg.duration.inMinutes / totalMinutes) * 2 * pi;
      if (sweep < 0.01) continue;
      canvas.drawArc(rect, startAngle + 0.04, sweep - 0.08, false, paint..color = seg.color..strokeCap = StrokeCap.round);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(AuraDashboardPiePainter old) => old.totalMinutes != totalMinutes || old.segments.length != segments.length;
}