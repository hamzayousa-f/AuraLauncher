import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class AuraAppModel {
  final String name;
  final String packageName;
  final Uint8List? iconBytes;

  AuraAppModel({required this.name, required this.packageName, this.iconBytes});
}

class LauncherService {
  static const MethodChannel _channel = MethodChannel(
    'com.hamza.wellbeing.aura/launcher',
  );

  static Future<List<AuraAppModel>> getInstalledApps() async {
    try {
      final List<dynamic>? apps = await _channel.invokeMethod(
        'getInstalledApps',
      );
      if (apps != null) {
        return apps.map((app) {
          final Map<dynamic, dynamic> appMap = app as Map<dynamic, dynamic>;
          final String base64Str = appMap['icon']?.toString() ?? '';

          Uint8List? decodedBytes;
          if (base64Str.isNotEmpty) {
            try {
              decodedBytes = base64Decode(base64Str);
            } catch (_) {
              decodedBytes = null;
            }
          }

          return AuraAppModel(
            name: appMap['name']?.toString() ?? '',
            packageName: appMap['package']?.toString() ?? '',
            iconBytes: decodedBytes,
          );
        }).toList();
      }
    } catch (e) {
      print("Failed to fetch installed apps: $e");
    }
    return [];
  }

  static Future<void> launchApp(String packageName) async {
    try {
      await _channel.invokeMethod('launchSystemApp', {
        'packageName': packageName,
      });
    } catch (e) {
      print("Failed to launch application target: $e");
    }
  }

  static Future<Map<String, dynamic>> getNativeBatteryStatus() async {
    try {
      final Map<dynamic, dynamic>? status = await _channel.invokeMethod(
        'getBatteryStatus',
      );
      if (status != null) {
        return {
          'level': status['level'] as int? ?? 100,
          'isCharging': status['isCharging'] as bool? ?? false,
        };
      }
    } catch (e) {
      print("Failed to pool native platform battery parameters: $e");
    }
    return {'level': 100, 'isCharging': false};
  }

  static Future<void> launchPhoneDialer() async =>
      await launchApp('com.android.dialer');
  static Future<void> launchWhatsApp() async => await launchApp('com.whatsapp');
}
