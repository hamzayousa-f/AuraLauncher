import 'package:flutter/services.dart';

class UsageService {
  static const MethodChannel _channel = MethodChannel('com.hamza.wellbeing.aura/launcher');

  /// Fetches real-time, accurate screen time metrics straight from the Android kernel.
  /// Returns a map of package names and their respective foreground usage in minutes.
  static Future<Map<String, int>> getZenithUsageData() async {
    try {
      final Map<dynamic, dynamic>? nativeData = 
          await _channel.invokeMethod('getNativeScreenTime');
      
      if (nativeData == null) return {};

      // Cast the native map safely to a structured Dart Map
      return nativeData.map((key, value) => MapEntry(key.toString(), value as int));
    } catch (e) {
      // Return an empty map on failure to prevent UI stalls; the clock will handle the fallback gracefully
      return {};
    }
  }
}