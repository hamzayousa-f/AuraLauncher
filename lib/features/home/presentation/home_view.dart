import 'dart:convert';
import 'package:flutter/services.dart'; // <-- ADD THIS LINE HERE
import 'dart:io';
import 'package:aura/features/home/widgets/notification_bell.dart';
import 'package:aura/features/home/widgets/notification_center_panel.dart';
import 'package:aura/features/home/widgets/tiling_dashboard.dart';
import 'package:aura/features/search/presentation/search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/shared/tactile_button.dart';
import '../../wallpaper/presentation/wallpaper_background.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/services/usage_service.dart';
import 'glass_clock.dart';
import 'bottom_dock.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  bool _isSearchOpen = false;
  Map<String, int> _usageStats = {};
  List<Map<String, String>> _pinnedAppsList = [];
  List<AuraAppModel> _cachedSystemApps = [];
  
  String _wallpaperType = 'solid';
  String _wallpaperPath = '0xFF0A0A0A';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHomeState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHomeState();
    }
  }

 int _notificationCount = 0;
  int _batteryLevel = 100;
  bool _isCharging = false;

  Future<void> _loadHomeState() async {
    final stats = await UsageService.getZenithUsageData();
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Fetch live native system values
    int nativeNotifications = 0;
    int nativeBattery = 100;
    bool nativeCharging = false;

    try {
      // Invoke your native MainActivity methods
      const channel = MethodChannel('com.hamza.wellbeing.aura/launcher');
      
      final Map<dynamic, dynamic>? batteryData = 
          await channel.invokeMethod<Map<dynamic, dynamic>>('getBatteryStatus');
      if (batteryData != null) {
        nativeBattery = batteryData['level'] ?? 100;
        nativeCharging = batteryData['isCharging'] ?? false;
      }

      // If your method channel name for count matches:
      final int? count = await channel.invokeMethod<int>('getNotificationCount');
      if (count != null) nativeNotifications = count;
    } catch (e) {
      debugPrint("System Channel Fetch Fail: $e");
    }

    setState(() {
      _usageStats = stats;
      _batteryLevel = nativeBattery;
      _isCharging = nativeCharging;
      _notificationCount = nativeNotifications;
      _wallpaperType = prefs.getString('wallpaper_type') ?? 'solid';
      _wallpaperPath = prefs.getString('wallpaper_path') ?? '0xFF0A0A0A';
    });

    // 2. Offload heavy package and icon scanning away from critical rendering startup
    Future.microtask(() async {
      final systemApps = await LauncherService.getInstalledApps();
      final savedPins = prefs.getStringList('pinned_custom_apps') ?? [];

      List<Map<String, String>> temporaryPinsList = [];
      for (String pkg in savedPins) {
        final match = systemApps.firstWhere(
          (app) => app.packageName == pkg, 
          orElse: () => AuraAppModel(name: '', packageName: '')
        );
        
        if (match.packageName.isEmpty) continue;

        temporaryPinsList.add({
          'name': match.name,
          'package': pkg,
          'icon': match.iconBytes != null ? base64Encode(match.iconBytes!) : '', 
        });
      }

      if (mounted) {
        setState(() {
          _cachedSystemApps = systemApps;
          _pinnedAppsList = temporaryPinsList;
        });
      }
    });
  }

  Future<void> _unpinApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPins = prefs.getStringList('pinned_custom_apps') ?? [];
    savedPins.remove(packageName);
    await prefs.setStringList('pinned_custom_apps', savedPins);
    
    _loadHomeState();
  }

  void _showWallpaperPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) {
        return GlassTheme.buildGlassPanel(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Workspace Canvas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 24),
              
              TactileButton(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 100,
                  );

                  if (image != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('wallpaper_type', 'file');
                    await prefs.setString('wallpaper_path', image.path);
                    
                    if (context.mounted) Navigator.pop(context);
                    _loadHomeState();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.photo_library_rounded, color: Colors.cyanAccent, size: 20),
                      SizedBox(width: 16),
                      Text("Open System Gallery", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              TactileButton(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('wallpaper_type', 'solid');
                  await prefs.setString('wallpaper_path', '0xFF0A0A0A');
                  if (context.mounted) Navigator.pop(context);
                  _loadHomeState();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.blur_on_rounded, color: Colors.white30, size: 20),
                      SizedBox(width: 16),
                      Text("Solid Obsidian Void", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Color _getUsageColor(int minutes) {
    if (minutes >= 120) return Colors.redAccent.withOpacity(0.85);
    if (minutes >= 60) return Colors.amberAccent.withOpacity(0.85);
    return Colors.white38;
  }

  void _openNotificationTray() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black38,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const NotificationCenterPanel();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Native Android QS Panel style sliding ease-down transition
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08), 
              end: Offset.zero
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearchOpen) {
          setState(() => _isSearchOpen = false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false, // <-- ADD THIS LINE
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 350) {
              if (!_isSearchOpen) {
                setState(() => _isSearchOpen = true);
              }
            }
          },
          child: Stack(
            children: [
              WallpaperBackground(
                onLongPressHome: () {
                  Feedback.forLongPress(context);
                  _showWallpaperPickerSheet(context);
                }, 
                wallpaperType: _wallpaperType,
                wallpaperPath: _wallpaperPath,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        const GlassClock(),
                        
                        const Spacer(),

                        // Pinned cleanly to the left margin with exact listener hook configurations
                        Align(
                          alignment: Alignment.centerLeft,
                          child: NotificationBell(onTap: _openNotificationTray),
                        ),
                        
                        const SizedBox(height: 14),
                        
                        // Core Pinned Container with Premium Specular Borders
                        GlassTheme.buildGlassPanel(
                          borderRadius: BorderRadius.circular(28),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                             Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10.0),
  child: TilingDashboard(
    usageStats: _usageStats,
    notificationCount: _notificationCount, // Live native notifications count
    batteryLevel: _batteryLevel,           // Live native battery metric
    isCharging: _isCharging,               // Live charging status indicator
  ),
),
                              
                              if (_pinnedAppsList.isNotEmpty) 
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0),
                                  child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
                                ),

                              ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _pinnedAppsList.length,
                                itemBuilder: (context, index) {
                                  final app = _pinnedAppsList[index];
                                  final String pkgName = app['package']!;

                                  return Dismissible(
                                    key: Key(pkgName),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) async {
                                      final String removedAppName = app['name']!;
                                      await _unpinApp(pkgName);
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.white10,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            content: Text(
                                              'Removed $removedAppName from focus layout',
                                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 28.0),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.label_off_rounded, 
                                        color: Colors.redAccent, 
                                        size: 18
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Column(
                                        children: [
                                          if (index > 0) 
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                                              child: Divider(color: Colors.white.withOpacity(0.04), height: 1),
                                            ),
                                          _buildTitleAppRow(
                                            appName: app['name']!,
                                            packageName: pkgName,
                                            isPermanent: false,
                                            iconData: Icons.apps_rounded,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              if (_pinnedAppsList.isEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0),
                                  child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                                  child: Text(
                                    "Long-press workspace to set wallpaper. Swipe down to focus apps.",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.2), 
                                      fontSize: 11, 
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        
                        BottomDock(
                          onSearchTap: () => setState(() => _isSearchOpen = true),
                          onPhoneTap: () => LauncherService.launchPhoneDialer(),
                          onWhatsAppTap: () => LauncherService.launchWhatsApp(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_isSearchOpen)
                SearchOverlay(
                  preloadedApps: _cachedSystemApps,
                  onClose: () {
                    setState(() => _isSearchOpen = false);
                    _loadHomeState();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAppRow({
    required String appName,
    required String packageName,
    required bool isPermanent,
    required IconData iconData,
  }) {
    final int minutes = _usageStats[packageName] ?? 0;
    final Color usageColor = _getUsageColor(minutes);
    final String displayTime = minutes >= 60 
        ? '${(minutes / 60).floor()}h ${minutes % 60}m'
        : '${minutes}m';

    final appMatch = _pinnedAppsList.firstWhere(
      (element) => element['package'] == packageName, 
      orElse: () => {}
    );
    final String base64Icon = appMatch['icon'] ?? '';

    const List<double> grayscaleMatrix = <double>[
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0,    0,    0,    0.45, 0, 
    ];

    return TactileButton(
      onTap: () => LauncherService.launchApp(packageName),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: isPermanent
                  ? Icon(iconData, color: Colors.cyanAccent.withOpacity(0.75), size: 18)
                  : base64Icon.isNotEmpty 
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.matrix(grayscaleMatrix),
                          child: Image.memory(
                            base64Decode(base64Icon), 
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium, 
                          ),
                        )
                      : Icon(iconData, color: Colors.white30, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                appName,
                style: TextStyle(
                  color: isPermanent ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: isPermanent ? FontWeight.w500 : FontWeight.w400,
                  letterSpacing: -0.1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Text(
              displayTime,
              style: TextStyle(
                color: usageColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}