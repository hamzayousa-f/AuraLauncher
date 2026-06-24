import 'package:flutter/services.dart';

class DartNotificationService {
  static const MethodChannel _channel = MethodChannel('com.hamza.wellbeing.aura/launcher');

  static Future<int> getNotificationCount() async {
    try {
      final int count = await _channel.invokeMethod('getNotificationCount');
      return count;
    } catch (e) {
      return 0;
    }
  }

  // Fetches the structural content details of the active notification cache
  static Future<List<Map<String, String>>> getActiveNotifications() async {
    try {
      final List<dynamic> rawList = await _channel.invokeMethod('getActiveNotifications');
      return rawList.map((item) => Map<String, String>.from(item)).toList();
    } catch (e) {
      print("Aura Core: Error reading notification metadata stream: $e");
      return [];
    }
  }

  static Future<bool> checkNotificationPermission() async {
    try {
      return await _channel.invokeMethod('checkNotificationPermission');
    } catch (e) {
      return false;
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      print("Failed to open settings panel: $e");
    }
  }
}