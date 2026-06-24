import 'dart:convert';
import 'package:aura/features/search/presentation/search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/glass_theme.dart';
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
    // Automatically re-query active files when returning to launcher view space
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
      
      // If the app is no longer present on device, bypass completely
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
    if (minutes >= 120) return Colors.redAccent;
    if (minutes >= 60) return Colors.yellowAccent;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 350) {
            if (!_isSearchOpen) {
              setState(() {
                _isSearchOpen = true;
              });
            }
          }
        },
        child: Stack(
          children: [
            WallpaperBackground(
              onLongPressHome: () {}, 
              wallpaperType: _wallpaperType,
              wallpaperPath: _wallpaperPath,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const GlassClock(),
                      
                      const Spacer(),
                      
                      GlassTheme.buildGlassPanel(
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: _buildTitleAppRow(
                                appName: 'Zenith',
                                packageName: 'com.hamza.wellbeing.zenith',
                                isPermanent: true,
                                iconData: Icons.hourglass_empty_rounded,
                              ),
                            ),
                            
                            if (_pinnedAppsList.isNotEmpty) const Divider(color: Colors.white10, height: 12),

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
                                          content: Text('Unpinned $removedAppName'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24.0),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.label_off_rounded, color: Colors.redAccent, size: 20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      children: [
                                        if (index > 0) const Divider(color: Colors.white10, height: 12),
                                        _buildTitleAppRow(
                                          appName: app['name']!,
                                          packageName: pkgName,
                                          isPermanent: false,
                                          iconData: Icons.android_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            if (_pinnedAppsList.isEmpty) ...[
                              const Divider(color: Colors.white10, height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  "Swipe down anywhere or tap Search to begin",
                                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11, fontStyle: FontStyle.italic),
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
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => LauncherService.launchApp(packageName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: isPermanent
                    ? Icon(iconData, color: Colors.cyanAccent.withOpacity(0.8), size: 22)
                    : base64Icon.isNotEmpty 
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.matrix(grayscaleMatrix),
                            child: Image.memory(base64Decode(base64Icon), fit: BoxFit.contain),
                          )
                        : Icon(iconData, color: Colors.white70, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  appName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: isPermanent ? FontWeight.w600 : FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Text(
                displayTime,
                style: TextStyle(
                  color: usageColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}