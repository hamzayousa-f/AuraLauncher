import 'package:aura/features/blocker/data/blocker_profile.dart';
import 'package:aura/features/blocker/presentation/views/fluid_friction_overlay.dart';
import 'package:aura/features/home/presentation/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AuraApp());
}

class AuraApp extends StatelessWidget {
  const AuraApp({Key? key}) : super(key: key);

  // Global static key allows navigation from anywhere, ignoring stale local widget lifecycle trees
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Launcher',
      navigatorKey: AuraApp.navigatorKey, // Bind key here
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const AuraHomeScreen(),
    );
  }
}

class AuraHomeScreen extends StatefulWidget {
  const AuraHomeScreen({Key? key}) : super(key: key);

  @override
  State<AuraHomeScreen> createState() => _AuraHomeScreenState();
}

class _AuraHomeScreenState extends State<AuraHomeScreen> {
  static const _channel = MethodChannel('com.hamza.wellbeing.aura/launcher');

  @override
  void initState() {
    super.initState();
    _initBlockerListener();
  }

  void _initBlockerListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "nativeAppBlockedIntercepted") {
        // Parse arguments as a map layout from Kotlin
        final Map<dynamic, dynamic>? args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final String? blockedPackage = args['packageName'] as String?;
          final bool isLimitReached = args['isLimitReached'] as bool? ?? false;

          if (blockedPackage != null) {
            _routeToFrictionOverlay(blockedPackage, isLimitReached);
          }
        }
      }
    });
  }

  void _routeToFrictionOverlay(String packageName, bool isLimitReached) {
    // Dynamically adjust allocation maps depending on the true native intent parameters
    final dynamicProfile = BlockerProfile(
      packageId: packageName,
      readableName: packageName.split('.').last.toUpperCase(),
      visualIcon: Icons.hourglass_empty_rounded,
      isRestricted: true,
      allocationLimitMinutes: 30,
      // If time limit is reached, set accumulation higher than limit to trigger your hard block UI.
      // Otherwise, set it to 0 so FluidFrictionOverlay falls back to the 5-second countdown loop.
      currentAccumulatedMinutes: isLimitReached ? 35 : 0, 
      IsSecurityEnforced: false,
      accessPinCode: "1234",
    );

    // Route using the master global layout state context key
    AuraApp.navigatorKey.currentState?.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => FluidFrictionOverlay(
          profile: dynamicProfile,
          onOverrideUnlocked: () {
            debugPrint("App override authorized for $packageName");
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const HomeView(); 
  }
}