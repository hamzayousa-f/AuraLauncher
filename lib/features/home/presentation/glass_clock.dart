import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/glass_theme.dart';

class GlassClock extends StatefulWidget {
  const GlassClock({super.key});

  @override
  State<GlassClock> createState() => _GlassClockState();
}

class _GlassClockState extends State<GlassClock> {
  late Timer _timer;
  String _timeString = '';
  String _dateString = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _timeString = DateFormat('hh:mm').format(now);
      _dateString = DateFormat('EEE, MMMM d').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassTheme.buildGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _timeString,
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w200,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 1.5,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 10),
          Text(
            _dateString.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
