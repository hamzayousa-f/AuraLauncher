import 'package:aura/features/blocker/presentation/views/fluid_friction_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/notification_service.dart';
import 'core/services/launcher_service.dart';
import 'features/blocker/data/blocker_service.dart';
import 'features/home/presentation/home_view.dart';
// Ensure this path exactly maps your FluidFrictionOverlay layout structure

// CRITICAL: Global key to allow routing without local screen BuildContext access
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize blocker service and load saved profiles
  await BlockerService.instance.fetchInstalledApps();
  
  // Set up blocker callback in launcher service
  LauncherService.shouldBlockAppCallback = (packageName) async {
    final bool isBlocked = BlockerService.instance.shouldBlockApp(packageName);
    
    if (isBlocked) {
      final profile = BlockerService.instance.getProfileForPackage(packageName);
      
      if (profile != null && globalNavigatorKey.currentState != null) {
        // Run on the next microtask frame to prevent thread lock-ups during execution loops
        Future.microtask(() {
          globalNavigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => FluidFrictionOverlay(
                profile: profile,
                onOverrideUnlocked: () {
  // Directly flip the restriction state flag on the profile instance
  profile.isRestricted = false; 
  
  // Save the updated profile down to the service state machine
  BlockerService.instance.updateProfile(profile);
},
              ),
            ),
          );
        });
      }
    }
    
    return isBlocked;
  };
  
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
      // FIXED: Injects the global state pipeline so background functions can route layout views
      navigatorKey: globalNavigatorKey, 
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, 
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}