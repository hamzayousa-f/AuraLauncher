import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/services/launcher_service.dart';

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
  int _currentCardIndex = 0; 

  @override
  void initState() {
    super.initState();
    
    // Smooth tick update loop for the main time parameters
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    // 8-second slow kinetic rotation between battery status and atmospheric phrasing
    _rotationTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      if (!mounted) return;
      if (_currentCardIndex == 0) {
        await _refreshBatteryMetrics();
      }
      setState(() {
        _currentCardIndex = (_currentCardIndex + 1) % 2;
      });
    });

    _refreshBatteryMetrics();
  }

  Future<void> _refreshBatteryMetrics() async {
    try {
      final batteryData = await LauncherService.getNativeBatteryStatus();
      if (mounted) {
        setState(() {
          _batteryLevel = batteryData['level'] as int;
          _isCharging = batteryData['isCharging'] as bool;
        });
      }
    } catch (_) {
      // Clean silent boundary fallback
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

  /// Evaluates system clock constraints to return studio-grade literary tokens
  Map<String, String> _getAtmosphericTokens() {
    final int hour = _now.hour;

    if (hour >= 5 && hour < 8) {
      return {'primary': 'SEHAR', 'secondary': 'AURORA // DAWN'};
    } else if (hour >= 8 && hour < 12) {
      return {'primary': 'CHASHT', 'secondary': 'FORENOON LIGHT'};
    } else if (hour >= 12 && hour < 15) {
      return {'primary': 'ZAWAAL', 'secondary': 'ZENITH // NOON'};
    } else if (hour >= 15 && hour < 18) {
      return {'primary': 'SE_PEHR', 'secondary': 'GOLDEN HOUR'};
    } else if (hour >= 18 && hour < 21) {
      return {'primary': 'SHAFAQ', 'secondary': 'CREPUSCULAR'};
    } else {
      return {'primary': 'SUKOON', 'secondary': 'NOCTURNAL // VOID'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final String hour = _now.hour.toString().padLeft(2, '0');
    final String minute = _now.minute.toString().padLeft(2, '0');

    return Row(
      children: [
        // Left Panel: Asymmetric Typographic Chrono Node
        Expanded(
          child: SizedBox(
            height: 106,
            child: GlassTheme.buildGlassPanel(
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    textBaseline: TextBaseline.alphabetic,
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
                          color: Colors.white.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.35),
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
        
        // Right Panel: The Atmospheric / System Void Node
        Expanded(
          child: SizedBox(
            height: 106,
            child: GlassTheme.buildGlassPanel(
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _currentCardIndex == 0 ? _buildAtmosphericCard() : _buildBatteryCard(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAtmosphericCard() {
    final tokens = _getAtmosphericTokens();

    return Column(
      key: const ValueKey<int>(0),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.lens_blur_rounded, 
          color: Colors.white.withOpacity(0.25), 
          size: 16
        ),
        const SizedBox(height: 8),
        Text(
          tokens['primary']!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tokens['secondary']!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
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
          _isCharging ? Icons.bolt_rounded : Icons.hdr_strong_rounded, 
          color: _isCharging ? Colors.cyanAccent.withOpacity(0.8) : Colors.white24, 
          size: 16
        ),
        const SizedBox(height: 8),
        Text(
          '$_batteryLevel%',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isCharging ? 'ENERGY SYNC' : 'BATTERY INDEX',
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}