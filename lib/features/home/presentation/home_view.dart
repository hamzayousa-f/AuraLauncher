import 'dart:convert';
import 'package:aura/features/search/presentation/search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  String _wallpaperType = 'asset';
  String _wallpaperPath = 'assets/wallpapers/default_noir.jpg';

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

  Future<void> _loadHomeState() async {
    final stats = await UsageService.getZenithUsageData();
    final prefs = await SharedPreferences.getInstance();
    
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

    setState(() {
      _usageStats = stats;
      _cachedSystemApps = systemApps;
      _pinnedAppsList = temporaryPinsList;
      _wallpaperType = prefs.getString('wallpaper_type') ?? 'asset';
      _wallpaperPath = prefs.getString('wallpaper_path') ?? 'assets/wallpapers/default_noir.jpg';
    });
  }

  Future<void> _unpinApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPins = prefs.getStringList('pinned_custom_apps') ?? [];
    savedPins.remove(packageName);
    await prefs.setStringList('pinned_custom_apps', savedPins);
    
    _loadHomeState();
  }

  Color _getUsageColor(int minutes) {
    if (minutes >= 120) return Colors.redAccent.withOpacity(0.85);
    if (minutes >= 60) return Colors.amberAccent.withOpacity(0.85);
    return Colors.white38;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents system back gestures from popping/reloading the home launcher
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Micro-Routing: If search drawer is open, back gesture elegantly closes it first
        if (_isSearchOpen) {
          setState(() => _isSearchOpen = false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
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
                  // Trigger a gentle haptic buzz on long-press
                  Feedback.forLongPress(context);
                  
                  // Open your visual customizer drawer or bottom sheet
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
                        
                        // Core Pinned Container with Premium Specular Borders
                        GlassTheme.buildGlassPanel(
                          borderRadius: BorderRadius.circular(28),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: _buildTitleAppRow(
                                  appName: 'Zenith Dashboard',
                                  packageName: 'com.hamza.wellbeing.zenith',
                                  isPermanent: true,
                                  iconData: Icons.blur_on_rounded,
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
                                    "Swipe down or tap Search to curate your focus layout",
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

    // Studio-Grade custom luminance matrix matching premium minimalist setups
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
            // Icon Nest with Grayscale Masking
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
            
            // Clean Monospace Typographic Contrast
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
            
            // Subtle metric timestamp
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
                "Interface Canvas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Select a background matrix for your focus workspace",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Option 1: Minimalist Solid Dark
              TactileButton(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('wallpaper_type', 'solid');
                  await prefs.setString('wallpaper_path', '0xFF0A0A0A');
                  Navigator.pop(context);
                  _loadHomeState();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.lens, color: Colors.white30, size: 20),
                      SizedBox(width: 16),
                      Text("Solid Obsidian Noir", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Option 2: Default Image Asset
              TactileButton(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('wallpaper_type', 'asset');
                  await prefs.setString('wallpaper_path', 'assets/wallpapers/default_noir.jpg');
                  Navigator.pop(context);
                  _loadHomeState();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.image_outlined, color: Colors.white30, size: 20),
                      SizedBox(width: 16),
                      Text("Default Cinematic Asset", style: TextStyle(color: Colors.white70, fontSize: 14)),
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
}