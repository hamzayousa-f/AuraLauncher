import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/services/usage_service.dart';

class GlassClock extends StatefulWidget {
  const GlassClock({super.key});

  @override
  State<GlassClock> createState() => _GlassClockState();
}

class _GlassClockState extends State<GlassClock> {
  DateTime _now = DateTime.now();
  late Timer _timeTimer;
  late Timer _rotationTimer;

  // Hardware Parameters
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _batterySubscription;

  int _totalZenithMinutes = 0;
  int _currentCardIndex = 0; // 0 = Zenith Tracking, 1 = Battery Status

  @override
  void initState() {
    super.initState();

    // 1. Dedicated UI Time Clock Ticker (Runs independently)
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    // 2. Load Init Hardware Telemetry
    _loadBatteryMetrics();

    // 3. Robust Rotation Loop - Safely handles refresh states every 5 seconds
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;

      // If switching to the Zenith card, fetch fresh analytics data defensively
      if (_currentCardIndex == 1) {
        await _refreshZenithStats();
      } else {
        _loadBatteryMetrics();
      }

      setState(() {
        _currentCardIndex = (_currentCardIndex + 1) % 2;
      });
    });

    // Run an initial immediate fetch for Zenith metrics
    _refreshZenithStats();
  }

  Future<void> _refreshZenithStats() async {
    try {
      final usageData = await UsageService.getZenithUsageData();
      int totalMinutes = 0;
      if (usageData.isNotEmpty) {
        usageData.forEach((key, value) => totalMinutes += value);
      }
      if (mounted) {
        setState(() {
          _totalZenithMinutes = totalMinutes;
        });
      }
    } catch (e) {
      debugPrint(
        "Zenith database engine tracking metrics not available yet: $e",
      );
      // Fail safely without freezing the widget state trees
      if (mounted) {
        setState(() {
          _totalZenithMinutes = 0;
        });
      }
    }
  }

  Future<void> _loadBatteryMetrics() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    } catch (_) {}

    _batterySubscription ??= _battery.onBatteryStateChanged.listen((
      BatteryState state,
    ) {
      if (mounted) {
        setState(() {
          _batteryState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeTimer.cancel();
    _rotationTimer.cancel();
    _batterySubscription?.cancel();
    super.dispose();
  }

  String _getFormattedDate() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[_now.weekday - 1]}, ${months[_now.month - 1]} ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final String hour = _now.hour.toString().padLeft(2, '0');
    final String minute = _now.minute.toString().padLeft(2, '0');

    return Row(
      children: [
        // Primary Time Panel
        Expanded(
          child: GlassTheme.buildGlassPanel(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$hour:$minute',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Smart Contextual Rotating Panel
        Expanded(
          child: GlassTheme.buildGlassPanel(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _currentCardIndex == 0
                  ? _buildZenithCard()
                  : _buildBatteryCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZenithCard() {
    final int hours = (_totalZenithMinutes / 60).floor();
    final int mins = _totalZenithMinutes % 60;
    final String timeDisplay = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Column(
      key: const ValueKey<int>(0),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.hourglass_empty_rounded,
          color: Colors.cyanAccent.withOpacity(0.8),
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          timeDisplay,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Zenith Screen Time',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildBatteryCard() {
    final bool isCharging = _batteryState == BatteryState.charging;

    return Column(
      key: const ValueKey<int>(1),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isCharging ? Icons.bolt_rounded : Icons.battery_charging_full_rounded,
          color: isCharging ? Colors.greenAccent : Colors.white70,
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          '$_batteryLevel%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isCharging ? 'Charging Device' : 'Battery Status',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
        ),
      ],
    );
  }
}
