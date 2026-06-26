import 'package:aura/features/blocker/data/blocker_profile.dart';
import 'package:aura/features/blocker/presentation/views/fluid_friction_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AuraApp());
}

class AuraApp extends StatelessWidget {
  const AuraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Launcher',
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
        final String? blockedPackage = call.arguments as String?;
        if (blockedPackage != null) {
          _routeToFrictionOverlay(blockedPackage);
        }
      }
    });
  }

  void _routeToFrictionOverlay(String packageName) {
    // Generate the blocker profile using correct properties to satisfy the hasExceededLimit getter rules
    final mockProfile = BlockerProfile(
      packageId: packageName,
      readableName: packageName.split('.').last.toUpperCase(),
      visualIcon: Icons.hourglass_empty_rounded,
      isRestricted: true,
      allocationLimitMinutes: 30,
      currentAccumulatedMinutes: 0, // 0 / 30 retains hasExceededLimit as false
      IsSecurityEnforced: false,
      accessPinCode: "1234",
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => FluidFrictionOverlay(
          profile: mockProfile,
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
    return const Scaffold(
      body: Center(
        child: Text(
          "Aura",
          style: TextStyle(
            color: Colors.white24,
            fontSize: 32,
            fontWeight: FontWeight.w200,
            letterSpacing: 4.0,
          ),
        ),
      ),
    );
  }
}