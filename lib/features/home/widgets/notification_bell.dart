import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';

class NotificationBell extends StatefulWidget {
  final VoidCallback onTap;

  const NotificationBell({super.key,  required this.onTap});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _notificationCount = 0;
  Timer? _fetchTimer;

  @override
  void initState() {
    super.initState();
    _updateCount();
    // Poll the native layer every 3 seconds to keep things performant but accurate
    _fetchTimer = Timer.periodic(const Duration(seconds: 3), (timer) => _updateCount());
  }

  Future<void> _updateCount() async {
    final int currentCount = await DartNotificationService.getNotificationCount();
    if (mounted && currentCount != _notificationCount) {
      setState(() {
        _notificationCount = currentCount;
      });
    }
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Frosted Glass Base Container
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          // High-Contrast Red Notification Dot/Badge
          if (_notificationCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '$_notificationCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}