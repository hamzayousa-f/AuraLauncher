import 'package:flutter/material.dart';
import '../../../../core/shared/tactile_button.dart';
import '../presentation/dashboard_view.dart';

// ─── Pre-computed colour constants ────────────────────────────────────────────

const _kWhite02   = Color(0x05FFFFFF);
const _kWhite04   = Color(0x0AFFFFFF);
const _kWhite05   = Color(0x0DFFFFFF);
const _kWhite20   = Color(0x33FFFFFF);
const _kWhite70   = Color(0xB3FFFFFF);
const _kAmber     = Color(0xCCFFD740);
const _kCyan      = Color(0xCC84FFFF);
const _kRed       = Color(0xCCFF5252);

// ─── Route factory ────────────────────────────────────────────────────────────
// PageRouteBuilder is single-use (disposed after pop), so we create a fresh
// instance on every navigation call rather than caching it statically.

PageRouteBuilder<void> _buildDashboardRoute() => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => const AuraDashboardView(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );

// ─── Widget ───────────────────────────────────────────────────────────────────

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

  int get _finalMinutes {
    if (totalSystemMinutes != 0) return totalSystemMinutes;
    if (usageStats.isEmpty) return 0;
    return usageStats.values.fold(0, (sum, v) => sum + v);
  }

  String _screenTimeDisplay(int minutes) => minutes >= 60
      ? '${minutes ~/ 60}h ${minutes % 60}m'
      : '${minutes}m';

  int _focusIndex(int minutes) =>
      (100 - ((minutes / 120) * 10).round()).clamp(0, 100);

  Color _focusColor(int index) {
    if (index < 60) return _kRed;
    if (index < 85) return _kAmber;
    return _kCyan;
  }

  @override
  Widget build(BuildContext context) {
    final int minutes   = _finalMinutes;
    final int focus     = _focusIndex(minutes);
    final String screen = _screenTimeDisplay(minutes);

    return TactileButton(
      // Fresh route instance on every tap — PageRouteBuilder is single-use.
      onTap: () => Navigator.of(context).push(_buildDashboardRoute()),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: _kWhite02,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kWhite04),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Tile(
                  label: 'SCREEN',
                  val: screen,
                  color: minutes >= 150 ? _kAmber : _kWhite70,
                ),
              ),
              const _Divider(),
              Expanded(
                child: _Tile(
                  label: 'FOCUS INDEX',
                  val: '$focus%',
                  color: _focusColor(focus),
                ),
              ),
              const _Divider(),
              Expanded(
                child: _Tile(
                  label: 'ENERGY',
                  val: isCharging ? '$batteryLevel% ⚡' : '$batteryLevel%',
                  color: batteryLevel <= 20 ? _kRed : _kWhite70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.val, required this.color});

  final String label;
  final String val;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kWhite20,
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

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 1, height: 24, child: ColoredBox(color: _kWhite05));
}