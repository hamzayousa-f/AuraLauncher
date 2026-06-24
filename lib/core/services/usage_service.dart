import 'package:flutter/services.dart';

class UsageService {
  static const MethodChannel _channel = MethodChannel('com.hamza.wellbeing.aura/launcher');

  /// Fetches system app foreground metrics strictly bounded between today's 12:00 AM and now.
  static Future<Map<String, int>> getZenithUsageData() async {
    try {
      final now = DateTime.now();
      
      // Calculate local midnight (00:00:00 AM)
      final DateTime midnightToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
      
      final int startTimeMillis = midnightToday.millisecondsSinceEpoch;
      final int endTimeMillis = now.millisecondsSinceEpoch;

      final Map<dynamic, dynamic>? rawStats = await _channel.invokeMethod(
        'getAppUsageStats',
        {
          'startTime': startTimeMillis,
          'endTime': endTimeMillis,
        },
      );

      if (rawStats == null || rawStats.isEmpty) {
        print("UsageService: Received empty or null map from native platform layer.");
        return {};
      }
      
      final Map<String, int> processedStats = {};
      
      rawStats.forEach((key, value) {
        if (key != null && value != null) {
          // Safely parse values as generic numbers before transforming to integers
          // This prevents TypeCast exceptions if the engine bridges them dynamically
          final String pkgName = key.toString();
          final int minutes = (value as num).toInt();
          
          if (minutes > 0) {
            processedStats[pkgName] = minutes;
          }
        }
      });

      return processedStats;
    } catch (e, stackTrace) {
      // Diagnostic logging to reveal any hidden underlying channel issues
      print("UsageService Exception caught: $e");
      print("Stacktrace: $stackTrace");
      return {};
    }
  }
}