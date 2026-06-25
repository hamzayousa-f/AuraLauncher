import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/services/notification_service.dart';

class NotificationCenterPanel extends StatefulWidget {
  const NotificationCenterPanel({super.key});

  @override
  State<NotificationCenterPanel> createState() => _NotificationCenterPanelState();
}

class _NotificationCenterPanelState extends State<NotificationCenterPanel> {
  List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveNotifications();
  }

  Future<void> _fetchLiveNotifications() async {
    final data = await DartNotificationService.getActiveNotifications();
    if (mounted) {
      setState(() => _notifications = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Material(
            color: Colors.transparent,
            child: GlassTheme.buildGlassPanel(
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Notification Center",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          "System clear. No unread items.",
                          style: TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 16),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                                child: const Icon(Icons.notifications_active_rounded, color: Colors.cyanAccent, size: 14),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'Notification',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['text'] ?? '',
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}