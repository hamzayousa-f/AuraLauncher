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

    // Map saved package tokens back to visible titles
    List<Map<String, String>> temporaryPinsList = [];
    for (String pkg in savedPins) {
      final match = systemApps.firstWhere(
        (app) => app['package'] == pkg,
        orElse: () => {'name': 'App', 'package': pkg},
      );
      temporaryPinsList.add({'name': match['name']!, 'package': pkg});
    }

    setState(() {
      _usageStats = stats;
      _pinnedAppsList = temporaryPinsList;
    });
  }

  void _showWallpaperMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassTheme.buildGlassPanel(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          padding: const EdgeInsets.all(24),
          child: Container(
            height: 200,
            width: double.infinity,
            alignment: Alignment.center,
            child: const Text(
              'Wallpaper Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    return Stack(
      children: [
        WallpaperBackground(
          onLongPressHome: _showWallpaperMenu,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                GlassClock(),

                const Spacer(),

                // Clean Title Section Layout Container Box
                GlassTheme.buildGlassPanel(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Zenith: Fixed permanently at the top of the rows layout
                      _buildTitleAppRow(
                        appName: 'Zenith',
                        packageName: 'com.hamza.wellbeing.zenith',
                        isPermanent: true,
                        iconData: Icons.hourglass_empty_rounded,
                      ),

                      if (_pinnedAppsList.isNotEmpty)
                        const Divider(color: Colors.white10, height: 12),

                      // 2. The 3 Custom Pin Rows allocated from the Search screen
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

                      // Placeholder helper if slots are vacant
                      if (_pinnedAppsList.isEmpty) ...[
                        const Divider(color: Colors.white10, height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            "Long press apps inside Search to pin them here",
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
          AnimatedOpacity(
            opacity: _isSearchOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: SearchOverlay(
              onClose: () {
                setState(() => _isSearchOpen = false);
                _loadHomeState(); // Pull newly updated app lists back to home state
              },
            ),
          ),
      ],
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

    return InkWell(
      onTap: () => LauncherService.launchApp(packageName),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(
              iconData,
              color: isPermanent
                  ? Colors.cyanAccent.withOpacity(0.8)
                  : Colors.white70,
              size: 22,
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
    );
  }
}
