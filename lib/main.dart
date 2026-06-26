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
    // We intentionally force currentAccumulatedMinutes to 35 here.
    // Since 35 >= 30, the hasExceededLimit getter evaluates to TRUE 
    // and satisfies the visibility rule required to display the overlay layout.
    final mockProfile = BlockerProfile(
      packageId: packageName,
      readableName: packageName.split('.').last.toUpperCase(),
      visualIcon: Icons.hourglass_empty_rounded,
      isRestricted: true,
      allocationLimitMinutes: 30,
      currentAccumulatedMinutes: 35, 
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
    // Safely renders your real interactive dashboard layout as the home layer
    return const HomeView(); 
  }
}