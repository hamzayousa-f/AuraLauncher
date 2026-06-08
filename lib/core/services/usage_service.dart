import 'package:flutter/services.dart';

class UsageService {
  static const MethodChannel _channel = MethodChannel(
    'com.hamza.wellbeing.aura/launcher',
  );

  /// Fetches actual real-time screen-time statistics calculated natively by the system
  static Future<Map<String, int>> getZenithUsageData() async {
    try {
      // 1. Verify if system usage access is enabled
      final bool hasPermission =
          await _channel.invokeMethod('checkUsagePermission') ?? false;

      if (!hasPermission) {
        // Request authorization context interface safely
        await _channel.invokeMethod('openUsageSettings');
        return {};
      }

      // 2. Fetch the calculated midnight-to-now runtime map
      final Map<dynamic, dynamic>? nativeData = await _channel.invokeMethod(
        'getNativeScreenTime',
      );
      if (nativeData != null) {
        return nativeData.map(
          (key, value) =>
              MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0),
        );
      }
    } catch (e) {
      print("Error fetching native screen time logic details: $e");
    }
    return {};
  }
}
