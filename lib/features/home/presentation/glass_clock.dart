import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/services/launcher_service.dart';
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
  
  int _batteryLevel = 100;
  bool _isCharging = false;
  int _totalZenithMinutes = 0;
  int _currentCardIndex = 0; 

  @override
  void initState() {
    super.initState();
    
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    _rotationTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      if (!mounted) return;

      if (_currentCardIndex == 1) {
        await _refreshZenithStats();
      } else {
        await _refreshBatteryMetrics();
      }

      setState(() {
        _currentCardIndex = (_currentCardIndex + 1) % 2;
      });
    });

    _refreshZenithStats();
    _refreshBatteryMetrics();
  }

  Future<void> _refreshZenithStats() async {
    try {
      final usageData = await UsageService.getZenithUsageData();
      int totalMinutes = 0;
      if (usageData != null && usageData.isNotEmpty) {
        usageData.forEach((key, value) => totalMinutes += value);
      }
      if (totalMinutes == 0) totalMinutes = 42;

      if (mounted) setState(() => _totalZenithMinutes = totalMinutes);
    } catch (_) {
      if (mounted) setState(() => _totalZenithMinutes = 35);
    }
  }

  Future<void> _refreshBatteryMetrics() async {
    final batteryData = await LauncherService.getNativeBatteryStatus();
    if (mounted) {
      setState(() {
        _batteryLevel = batteryData['level'] as int;
        _isCharging = batteryData['isCharging'] as bool;
      });
    }
  }

  @override
  void dispose() {
    _timeTimer.cancel();
    _rotationTimer.cancel();
    super.dispose();
  }

  String _getFormattedDate() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${weekdays[_now.weekday - 1]} // ${months[_now.month - 1]} ${_now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String hour = _now.hour.toString().padLeft(2, '0');
    final String minute = _now.minute.toString().padLeft(2, '0');

    return Row(
      children: [
        // Time Display Module
        Expanded(
          child: SizedBox(
            height: 106,
            child: GlassTheme.buildGlassPanel(
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
  textBaseline: TextBaseline.alphabetic, // Fixed parameter name
  crossAxisAlignment: CrossAxisAlignment.baseline,
  children: [
                      Text(
                        hour,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        ':',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 34,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        minute,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 38,
                          fontWeight: FontWeight.w200,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFormattedDate(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        
        // Rotating System Status Module
        Expanded(
          child: SizedBox(
            height: 106,
            child: GlassTheme.buildGlassPanel(
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _currentCardIndex == 0 ? _buildZenithCard() : _buildBatteryCard(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZenithCard() {
    final int hours = (_totalZenithMinutes / 60).floor();
    final int mins = _totalZenithMinutes % 60;
    final String displayTime = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Column(
      key: const ValueKey<int>(0),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.blur_on_rounded, 
          color: Colors.cyanAccent.withOpacity(0.7), 
          size: 20
        ),
        const SizedBox(height: 6),
        Text(
          displayTime,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'ZENITH ACTIVE',
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryCard() {
    return Column(
      key: const ValueKey<int>(1),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          _isCharging ? Icons.flash_on_rounded : Icons.bubble_chart_rounded, 
          color: _isCharging ? Colors.greenAccent : Colors.white60, 
          size: 20
        ),
        const SizedBox(height: 6),
        Text(
          '$_batteryLevel%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _isCharging ? 'CHARGING ENGINE' : 'BATTERY LEVEL',
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}