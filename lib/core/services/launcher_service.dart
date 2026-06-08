import 'package:flutter/services.dart';

class LauncherService {
  static const MethodChannel _channel = MethodChannel(
    'com.hamza.wellbeing.aura/launcher',
  );

  static Future<void> launchApp(String packageName) async {
    try {
      await _channel.invokeMethod('launchSystemApp', {
        'packageName': packageName,
      });
    } on PlatformException catch (e) {
      print(
        "Failed to launch application package '$packageName': ${e.message}",
      );
    }
  }

  static Future<void> launchPhoneDialer() async =>
      launchApp('com.android.dialer');
  static Future<void> launchWhatsApp() async => launchApp('com.whatsapp');

  /// Fetches real installed applications from the native system layer
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getInstalledApps',
      );
      return result.map((app) {
        return {
          'name': app['name']?.toString() ?? 'Unknown App',
          'package': app['package']?.toString() ?? '',
        };
      }).toList();
    } on PlatformException catch (e) {
      print("Failed to fetch application directory index: ${e.message}");
      return [];
    }
  }
}
