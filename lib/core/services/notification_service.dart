import 'package:flutter/services.dart';

class DartNotificationService {
  static const MethodChannel _channel = MethodChannel('com.hamza.wellbeing.aura/launcher');

  /// Fetches the current unread active notification count from the native listener.
  static Future<int> getNotificationCount() async {
    try {
      final int count = await _channel.invokeMethod('getNotificationCount');
      return count;
    } catch (e) {
      print("DartNotificationService: Failed to fetch notification count: $e");
      return 0;
    }
  }

  /// Checks if Aura has permission to listen to the system's notification stream.
  static Future<bool> checkNotificationPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkNotificationPermission');
      return hasPermission;
    } catch (e) {
      print("DartNotificationService: Failed to check permission status: $e");
      return false;
    }
  }

  /// Opens the system Notification Listener Settings window.
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      print("DartNotificationService: Failed to open settings panel: $e");
    }
  }
}