import 'package:flutter/services.dart';

class UsageService {
  static const MethodChannel _channel = MethodChannel('com.hamza.wellbeing.aura/launcher');

  /// Fetches system app foreground metrics with a self-healing retry block for cold boots.
  static Future<Map<String, int>> getZenithUsageData({int retryCount = 0}) async {
    try {
      final now = DateTime.now();
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

      // If Android returns an empty map at boot, back off for 600ms and try one more time
      // This gives the system's background UsageStatsManager service time to initialize.
      if ((rawStats == null || rawStats.isEmpty) && retryCount < 1) {
        print("UsageService: Empty map at boot. Waiting for system subsystem initialization retry...");
        await Future.delayed(const Duration(milliseconds: 600));
        return getZenithUsageData(retryCount: retryCount + 1);
      }

      if (rawStats == null || rawStats.isEmpty) {
        return {};
      }
      
      final Map<String, int> processedStats = {};
      rawStats.forEach((key, value) {
        if (key != null && value != null) {
          final String pkgName = key.toString();
          final int minutes = (value as num).toInt();
          
          if (minutes > 0) {
            processedStats[pkgName] = minutes;
          }
        }
      });

      return processedStats;
    } catch (e, stackTrace) {
      print("UsageService Exception caught: $e");
      print("Stacktrace: $stackTrace");
      return {};
    }
  }
}