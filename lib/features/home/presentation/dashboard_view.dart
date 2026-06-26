import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/shared/tactile_button.dart';

// --- Local Presentation Models ---
class AuraPieSegment {
  final String label;
  final Duration duration;
  final Color color;

  AuraPieSegment({
    required this.label,
    required this.duration,
    required this.color,
  });
}

class AuraCategorySummary {
  final String name;
  final Duration duration;
  final double percentage;

  AuraCategorySummary({
    required this.name,
    required this.duration,
    required this.percentage,
  });
}

class AuraTopAppItem {
  final String name;
  final Duration duration;
  final String percentage;
  final IconData fallbackIcon;
  final Color markerColor;

  AuraTopAppItem({
    required this.name,
    required this.duration,
    required this.percentage,
    required this.fallbackIcon,
    required this.markerColor,
  });
}

// --- Main Dashboard View Widget ---
class AuraDashboardView extends StatelessWidget {
  const AuraDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Mock Data Pipelines matching Aura aesthetic palette tokens
    final Duration totalScreentime = const Duration(hours: 3, minutes: 42);
    final double totalMinutes = totalScreentime.inMinutes.toDouble();

    final List<Color> auraPalette = [
      const Color(0xFF818CF8), // Indigo
      const Color(0xFF60A5FA), // Soft Blue
      const Color(0xFF34D399), // Mint Green
      const Color(0xFFFBBF24), // Amber
    ];

    final List<AuraPieSegment> segments = [
      AuraPieSegment(label: 'Socials', duration: const Duration(hours: 1, minutes: 50), color: auraPalette[0]),
      AuraPieSegment(label: 'Dev/Prod', duration: const Duration(hours: 1, minutes: 0), color: auraPalette[1]),
      AuraPieSegment(label: 'Streaming', duration: const Duration(minutes: 40), color: auraPalette[2]),
      AuraPieSegment(label: 'Utilities', duration: const Duration(minutes: 12), color: auraPalette[3]),
    ];

    final List<AuraCategorySummary> categories = [
      AuraCategorySummary(name: 'Social Media', duration: const Duration(hours: 1, minutes: 50), percentage: 110 / totalMinutes),
      AuraCategorySummary(name: 'Productivity', duration: const Duration(hours: 1, minutes: 0), percentage: 60 / totalMinutes),
      AuraCategorySummary(name: 'Entertainment', duration: const Duration(minutes: 40), percentage: 40 / totalMinutes),
      AuraCategorySummary(name: 'System Utilities', duration: const Duration(minutes: 12), percentage: 12 / totalMinutes),
    ];

    final List<AuraTopAppItem> topApps = [
      AuraTopAppItem(name: 'Instagram', duration: const Duration(hours: 1, minutes: 25), percentage: '38%', fallbackIcon: Icons.camera_alt_rounded, markerColor: auraPalette[0]),
      AuraTopAppItem(name: 'GitHub Mobile', duration: const Duration(hours: 1, minutes: 0), percentage: '27%', fallbackIcon: Icons.code_rounded, markerColor: auraPalette[1]),
      AuraTopAppItem(name: 'YouTube ReVanced', duration: const Duration(minutes: 40), percentage: '18%', fallbackIcon: Icons.play_circle_fill_rounded, markerColor: auraPalette[2]),
    ];

    final int hours = totalScreentime.inHours;
    final int mins = totalScreentime.inMinutes.remainder(60);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Premium Ambient Blur Backplate
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Minimalist Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TactileButton(
                        onTap: () => Navigator.of(context).pop(),
                        child: _buildGlassIcon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const Text(
                        'ZENITH ENGINE',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                      _buildGlassIcon(Icons.bar_chart_rounded),
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

                  // 1st Component: Clean Vector Pie Chart Card
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
                                segments: segments,
                                totalMinutes: totalMinutes,
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
                                  fontFamily: 'JetBrains Mono',
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
                  _buildSectionHeader('Category Matrix'),
                  _buildGlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: List.generate(categories.length, (idx) {
                        final cat = categories[idx];
                        return Padding(
                          padding: EdgeInsets.only(bottom: idx == categories.length - 1 ? 0 : 16.0),
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
                                color: auraPalette[idx % auraPalette.length].withOpacity(0.8),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),);
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3rd Component: Top Consumer Channels
                  _buildSectionHeader('Top Consumer Channels'),
                  Column(
                    children: List.generate(topApps.length, (idx) {
                      final app = topApps[idx];
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.4),
          letterSpacing: 0.2,
        ),
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

// --- High-Performance Clean Pie Painter ---
class AuraDashboardPiePainter extends CustomPainter {
  final List<AuraPieSegment> segments;
  final double totalMinutes;
  final Color trackColor;

  AuraDashboardPiePainter({
    required this.segments,
    required this.totalMinutes,
    required this.trackColor,
  });

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

    double currentStartAngle = -pi / 2; // 12 o'clock
    const double angularGap = 0.07; 

    for (var segment in segments) {
      final double segmentMins = segment.duration.inMinutes.toDouble();
      if (segmentMins <= 0) continue;

      final double sweepAngle = (segmentMins / totalMinutes) * 2 * pi;
      double adjustedSweep = sweepAngle - angularGap;
      if (adjustedSweep < 0.02) adjustedSweep = 0.02;

      paintSegment.color = segment.color;
      canvas.drawArc(
        boundingSquare,
        currentStartAngle + (angularGap / 2),
        adjustedSweep,
        false,
        paintSegment,
      );

      currentStartAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant AuraDashboardPiePainter oldDelegate) {
    return oldDelegate.totalMinutes != totalMinutes || oldDelegate.segments.length != segments.length;
  }
}