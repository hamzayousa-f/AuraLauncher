import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui';
import 'package:aura/features/home/widgets/notification_bell.dart';
import 'package:aura/features/home/widgets/notification_center_panel.dart';
import 'package:aura/features/blocker/data/blocker_service.dart';
import 'package:aura/features/blocker/presentation/views/fluid_friction_overlay.dart';
import 'package:aura/features/home/widgets/tiling_dashboard.dart';
import 'package:aura/features/search/presentation/search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late AnimationController _gestureAnimationController;
  final ValueNotifier<double> _dragValueNotifier = ValueNotifier<double>(0.0);
  
  bool _isSearchOpen = false;
  Map<String, int> _usageStats = {};
  List<Map<String, String>> _pinnedAppsList = [];
  List<AuraAppModel> _cachedSystemApps = [];
  final Map<String, Uint8List> _decodedIconCache = {};
  
  String _wallpaperType = 'solid';
  String _wallpaperPath = '0xFF0A0A0A';

  int _notificationCount = 0;
  int _batteryLevel = 100;
  bool _isCharging = false;
  int _totalSystemScreenTime = 0;
  
  bool _isSyncingMetrics = false;
  bool _isAppCacheLoaded = false;
  bool _isPickingWallpaper = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _gestureAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220), 
    )..addListener(() {
        _dragValueNotifier.value = _gestureAnimationController.value;
      });
    
    _initialBootSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gestureAnimationController.dispose();
    _dragValueNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isPickingWallpaper) {
        _loadWallpaperConfig();
      }
      _loadVolatileSystemMetrics();
    }
  }

  Future<void> _initialBootSync() async {
    await _loadWallpaperConfig(); 
    
    // Unblock Main UI Pipeline Loop Frame
    Future.microtask(() async {
      await _loadVolatileSystemMetrics(); 
      await _buildAppStructureCache();
    });
  }

  Future<void> _loadWallpaperConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final type = prefs.getString('wallpaper_type') ?? 'solid';
      final path = prefs.getString('wallpaper_path') ?? '0xFF0A0A0A';
      
      debugPrint("🎨 Aura Config Sync: Loading Type ($type), Path ($path)");

      if (mounted) {
        setState(() {
          _wallpaperType = type;
          _wallpaperPath = path;
        });
      }
    } catch (e) {
      debugPrint("❌ Aura Error: Failed loading wallpaper config: $e");
    }
  }

  Future<void> _loadVolatileSystemMetrics() async {
    if (_isSyncingMetrics) return;
    _isSyncingMetrics = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, int> stats = {};
      
      try {
        stats = await UsageService.getZenithUsageData().timeout(
          const Duration(seconds: 2),
          onTimeout: () => <String, int>{},
        );
      } catch (e) {
        debugPrint("❌ Aura Error: UsageService timed out or dropped: $e");
      }

      int nativeNotifications = 0;
      int nativeBattery = 100;
      bool nativeCharging = false;
      int nativeTotalScreenTime = 0;

      const channel = MethodChannel('com.hamza.wellbeing.aura/launcher');
      
      try {
        final dynamic screenTimeResult = await channel.invokeMethod('getTotalSystemScreenTime').timeout(const Duration(milliseconds: 300));
        if (screenTimeResult != null) {
          nativeTotalScreenTime = (screenTimeResult as num).toInt();
        }
      } catch (e) {
        debugPrint("❌ Aura Error: Channel 'getTotalSystemScreenTime' failed: $e");
      }

      try {
        final dynamic batteryData = await channel.invokeMethod('getBatteryStatus').timeout(const Duration(milliseconds: 300));
        if (batteryData != null && batteryData is Map) {
          nativeBattery = (batteryData['level'] ?? 100 as num).toInt();
          nativeCharging = batteryData['isCharging'] ?? false;
        }
      } catch (e) {
        debugPrint("❌ Aura Error: Channel 'getBatteryStatus' failed: $e");
      }

      try {
        final dynamic notificationResult = await channel.invokeMethod('getNotificationCount').timeout(const Duration(milliseconds: 300));
        if (notificationResult != null) {
          nativeNotifications = (notificationResult as num).toInt();
        }
      } catch (e) {
        debugPrint("❌ Aura Error: Channel 'getNotificationCount' failed: $e");
      }

      if (mounted) {
        setState(() {
          _usageStats = stats;
          _totalSystemScreenTime = nativeTotalScreenTime;
          _batteryLevel = nativeBattery;
          _isCharging = nativeCharging;
          _notificationCount = nativeNotifications;
        });
      }
      
      if (_isAppCacheLoaded) {
        _mapPinnedAppIcons(prefs);
      }
    } catch (globalError) {
      debugPrint("❌ Aura Error: Global metrics loop broke: $globalError");
    } finally {
      _isSyncingMetrics = false;
    }
  }

  Future<void> _buildAppStructureCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final systemApps = await LauncherService.getInstalledApps();
      
      if (mounted) {
        setState(() {
          _cachedSystemApps = systemApps;
          _isAppCacheLoaded = true;
        });
        _mapPinnedAppIcons(prefs);
      }
    } catch (e) {
      debugPrint("Isolated App scanning sequence blocked: $e");
    }
  }

  void _mapPinnedAppIcons(SharedPreferences prefs) {
    final savedPins = prefs.getStringList('pinned_custom_apps') ?? [];
    List<Map<String, String>> temporaryPinsList = [];

    for (String pkg in savedPins) {
      final match = _cachedSystemApps.firstWhere(
        (app) => app.packageName == pkg, 
        orElse: () => AuraAppModel(name: '', packageName: '')
      );
      
      if (match.packageName.isEmpty) continue;

      if (match.iconBytes != null && !_decodedIconCache.containsKey(pkg)) {
        _decodedIconCache[pkg] = match.iconBytes!;
      }

      temporaryPinsList.add({
        'name': match.name,
        'package': pkg,
      });
    }

    if (mounted) {
      setState(() {
        _pinnedAppsList = temporaryPinsList;
      });
    }
  }

  Future<void> _unpinApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPins = prefs.getStringList('pinned_custom_apps') ?? [];
    savedPins.remove(packageName);
    await prefs.setStringList('pinned_custom_apps', savedPins);
    _decodedIconCache.remove(packageName);
    
    _mapPinnedAppIcons(prefs);
  }

  void _showWallpaperPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (sheetContext) {
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
                  try {
                    // Pop sheet instantly to prevent drawing lifecycle interaction holds
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }

                    // Let layout components process sheet closing frame safely
                    await Future.delayed(const Duration(milliseconds: 100));

                    if (mounted) {
                      setState(() => _isPickingWallpaper = true);
                    }

                    debugPrint("🚀 Triggering native ImagePicker channel...");
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 95,
                    );

                    if (image != null) {
                      debugPrint("📸 Native picker returned file path: ${image.path}");
                      
                      final Directory appDocDir = await getApplicationDocumentsDirectory();
                      final String permanentPath = '${appDocDir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
                      
                      final File savedFile = await File(image.path).copy(permanentPath);
                      
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('wallpaper_type', 'file');
                      await prefs.setString('wallpaper_path', savedFile.path);
                      await prefs.commit(); 

                      debugPrint("✅ Saved to Sandbox: ${savedFile.path}");
                      
                      if (mounted) {
                        setState(() {
                          _wallpaperType = 'file';
                          _wallpaperPath = savedFile.path;
                        });
                      }
                    } else {
                      debugPrint("⚠️ ImagePicker cancelled by user.");
                    }
                  } catch (err, stack) {
                    debugPrint("❌ CRITICAL ImagePicker Platform Failure: $err");
                    debugPrint("Stacktrace: $stack");
                  } finally {
                    if (mounted) {
                      setState(() => _isPickingWallpaper = false);
                    }
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
                  await prefs.commit();
                  
                  if (mounted) {
                    setState(() {
                      _wallpaperType = 'solid';
                      _wallpaperPath = '0xFF0A0A0A';
                    });
                  }

                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
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
        pageBuilder: (context, animation, secondaryAnimation) => const NotificationCenterPanel(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: () async {
            try {
              const channel = MethodChannel('com.hamza.wellbeing.aura/launcher');
              await channel.invokeMethod('turnOffScreen');
            } catch (e) {
              debugPrint("Failed to lock screen: $e");
            }
          },
          onVerticalDragUpdate: (details) {
            if (!_isSearchOpen && details.delta.dy > 0) {
              _gestureAnimationController.value += 
                  details.delta.dy / MediaQuery.of(context).size.height * 2.0;
            }
            else if (_gestureAnimationController.value > 0 && details.delta.dy < 0) {
              _gestureAnimationController.value += 
                  details.delta.dy / MediaQuery.of(context).size.height * 2.0;
            }
          },
          onVerticalDragEnd: (details) async {
            if (_gestureAnimationController.value > 0.18) {
              _gestureAnimationController.forward();
              try {
                const channel = MethodChannel('com.hamza.wellbeing.aura/launcher');
                await channel.invokeMethod('expandQuickSettings');
              } catch (e) {
                debugPrint("Status panel channel expansion failure: $e");
              }
              
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) _gestureAnimationController.reverse();
              });
            } else {
              _gestureAnimationController.reverse();
            }

            if (details.primaryVelocity != null && details.primaryVelocity! < -350) {
              if (!_isSearchOpen) {
                setState(() => _isSearchOpen = true);
              }
            }
          },
          child: Stack(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: _dragValueNotifier,
                builder: (context, dragValue, child) {
                  double blurSigma = dragValue * 6.0; 
                  double parallaxOffset = dragValue * 20.0;       
                  double wallpaperScale = 1.0 + (dragValue * 0.02);

                  return Stack(
                    children: [
                      Transform.translate(
                        offset: Offset(0, parallaxOffset),
                        child: Transform.scale(
                          scale: wallpaperScale,
                          child: WallpaperBackground(
                            onLongPressHome: () {
                              Feedback.forLongPress(context);
                              _showWallpaperPickerSheet(context);
                            }, 
                            wallpaperType: _wallpaperType,
                            wallpaperPath: _wallpaperPath,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      if (blurSigma > 0.1)
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                            child: Container(color: Colors.black.withOpacity(dragValue * 0.1)),
                          ),
                        ),
                    ],
                  );
                },
              ),

              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        const GlassClock(),
                        
                        const Spacer(),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: NotificationBell(onTap: _openNotificationTray),
                        ),
                        
                        const SizedBox(height: 14),
                        
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
                                  totalSystemMinutes: _totalSystemScreenTime,
                                  notificationCount: _notificationCount,
                                  batteryLevel: _batteryLevel,
                                  isCharging: _isCharging,
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
                    _loadVolatileSystemMetrics(); 
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

    final Uint8List? cachedBytes = _decodedIconCache[packageName];

    const List<double> grayscaleMatrix = <double>[
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0,    0,    0,    0.45, 0,
    ];

    return TactileButton(
      onTap: () async {
        final result = await LauncherService.launchApp(packageName);
        if (!mounted) return;

        if (result.blocked) {
          final profile = BlockerService.instance.getProfileForPackage(packageName);
          if (profile == null) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FluidFrictionOverlay(
                profile: profile,
                onOverrideUnlocked: () async {
                  await LauncherService.launchApp(packageName);
                },
              ),
            ),
          );
          return;
        }

        if (!result.success && result.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error!)),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: isPermanent
                  ? Icon(iconData, color: Colors.cyanAccent.withOpacity(.75), size: 18)
                  : cachedBytes != null
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.matrix(grayscaleMatrix),
                          child: Image.memory(
                            cachedBytes,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.low,
                            cacheWidth: 40,
                          ),
                        )
                      : Icon(iconData, color: Colors.white30, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                appName,
                style: TextStyle(
                  color: isPermanent ? Colors.white.withOpacity(.95) : Colors.white.withOpacity(.8),
                  fontSize: 15,
                  fontWeight: isPermanent ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              displayTime,
              style: TextStyle(color: usageColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}