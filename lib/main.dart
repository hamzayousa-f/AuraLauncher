import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _enforceUsagePermission();
  }

  /// Verifies permission telemetry at cold-boot and routes to native system settings if missing
  Future<void> _enforceUsagePermission() async {
    try {
      // 1. Interrogate the native engine context for existing authorization
      final bool hasPermission = await _platform.invokeMethod('checkUsagePermission');
      
      if (!hasPermission) {
        debugPrint("Aura Launcher Core: Telemetry access missing. Directing context to settings page.");
        // 2. Open the native Android settings menu directly to your app configuration
        await _platform.invokeMethod('openUsageSettings');
      } else {
        debugPrint("Aura Launcher Core: Usage permission matrix validated successfully.");
      }
    } on PlatformException catch (e) {
      debugPrint("Aura Launcher Core: Native permission channel threw an error: ${e.message}");
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