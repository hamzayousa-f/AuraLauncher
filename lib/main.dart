import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/notification_service.dart';
import 'features/home/presentation/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuraLauncher());
}

class AuraLauncher extends StatefulWidget {
  const AuraLauncher({super.key});

  @override
  State<AuraLauncher> createState() => _AuraLauncherState();
}

class _AuraLauncherState extends State<AuraLauncher> {
  static const MethodChannel _platform = MethodChannel('com.hamza.wellbeing.aura/launcher');

  @override
  void initState() {
    super.initState();
    _enforceSystemPermissions();
  }

  /// Sequentially enforces required system permissions at cold-boot
  Future<void> _enforceSystemPermissions() async {
    try {
      // 1. Enforce Usage Stats Permission
      final bool hasUsagePermission = await _platform.invokeMethod('checkUsagePermission');
      if (!hasUsagePermission) {
        debugPrint("Aura Launcher Core: Usage access missing. Directing to settings.");
        await _platform.invokeMethod('openUsageSettings');
        return; // Pause sequence until user returns
      }

      // 2. Enforce Notification Listener Permission
      final bool hasNotificationPermission = await DartNotificationService.checkNotificationPermission();
      if (!hasNotificationPermission) {
        debugPrint("Aura Launcher Core: Notification access missing. Directing to settings.");
        await DartNotificationService.openNotificationSettings();
      } else {
        debugPrint("Aura Launcher Core: All system security permission matrices validated.");
      }
    } on PlatformException catch (e) {
      debugPrint("Aura Launcher Core: Permission initialization error: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, 
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}