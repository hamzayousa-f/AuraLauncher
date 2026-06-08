import 'dart:convert';
import 'package:aura/core/services/launcher_service.dart';
import 'package:aura/core/services/usage_service.dart';
import 'package:aura/features/search/presentation/search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/glass_theme.dart';
import '../../wallpaper/presentation/wallpaper_background.dart';
import 'glass_clock.dart';
import 'bottom_dock.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isSearchOpen = false;
  Map<String, int> _usageStats = {};
  List<Map<String, String>> _pinnedAppsList = [];
  List<Map<String, String>> _cachedSystemApps = [];

  String _wallpaperType = 'asset';
  String _wallpaperPath = 'assets/wallpapers/default_noir.jpg';

  @override
  void initState() {
    super.initState();
    _loadHomeState();
  }

  Future<void> _loadHomeState() async {
    final stats = await UsageService.getZenithUsageData();
    final prefs = await SharedPreferences.getInstance();

    final systemApps = await LauncherService.getInstalledApps();
    final savedPins = prefs.getStringList('pinned_custom_apps') ?? [];

    List<Map<String, String>> temporaryPinsList = [];
    for (String pkg in savedPins) {
      final match = systemApps.firstWhere(
        (app) => app['package'] == pkg,
        orElse: () => {'name': 'App', 'package': pkg, 'icon': ''},
      );
      temporaryPinsList.add({
        'name': match['name']!,
        'package': pkg,
        'icon': match['icon'] ?? '',
      });
    }

    setState(() {
      _usageStats = stats;
      _cachedSystemApps = systemApps;
      _pinnedAppsList = temporaryPinsList;
      _wallpaperType = prefs.getString('wallpaper_type') ?? 'asset';
      _wallpaperPath =
          prefs.getString('wallpaper_path') ??
          'assets/wallpapers/default_noir.jpg';
    });
  }

  Future<void> _unpinApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPins = prefs.getStringList('pinned_custom_apps') ?? [];
    savedPins.remove(packageName);
    await prefs.setStringList('pinned_custom_apps', savedPins);

    _loadHomeState();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App unpinned from home view')),
      );
    }
  }

  void _showUnpinDialog(String appName, String packageName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassTheme.buildGlassPanel(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Manage $appName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.label_off_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Unpin from Home Screen',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _unpinApp(packageName);
                },
              ),
            ],
          ),
        );
      },
    );
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
      // Wrap your entire desktop footprint in a raw gesture interaction interceptor
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          // If the primary velocity value registers as positive, the user swiped downwards
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 350) {
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const GlassClock(),

                    const Spacer(),

                    GlassTheme.buildGlassPanel(
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTitleAppRow(
                            appName: 'Zenith',
                            packageName: 'com.hamza.wellbeing.zenith',
                            isPermanent: true,
                            iconData: Icons.hourglass_empty_rounded,
                          ),

                          if (_pinnedAppsList.isNotEmpty)
                            const Divider(color: Colors.white10, height: 12),

                          ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pinnedAppsList.length,
                            itemBuilder: (context, index) {
                              final app = _pinnedAppsList[index];
                              return Column(
                                children: [
                                  if (index > 0)
                                    const Divider(
                                      color: Colors.white10,
                                      height: 12,
                                    ),
                                  _buildTitleAppRow(
                                    appName: app['name']!,
                                    packageName: app['package']!,
                                    isPermanent: false,
                                    iconData: Icons.android_rounded,
                                  ),
                                ],
                              );
                            },
                          ),

                          if (_pinnedAppsList.isEmpty) ...[
                            const Divider(color: Colors.white10, height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Text(
                                "Swipe down anywhere or tap Search to begin",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    BottomDock(
                      onSearchTap: () => setState(() => _isSearchOpen = true),
                      onPhoneTap: () => LauncherService.launchPhoneDialer(),
                      onWhatsAppTap: () => LauncherService.launchWhatsApp(),
                    ),
                  ],
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
      orElse: () => {},
    );
    final String base64Icon = appMatch['icon'] ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => LauncherService.launchApp(packageName),
        onLongPress: isPermanent
            ? null
            : () => _showUnpinDialog(appName, packageName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: isPermanent
                    ? Icon(
                        iconData,
                        color: Colors.cyanAccent.withOpacity(0.8),
                        size: 22,
                      )
                    : base64Icon.isNotEmpty
                    ? Image.memory(
                        base64Decode(base64Icon),
                        fit: BoxFit.contain,
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
