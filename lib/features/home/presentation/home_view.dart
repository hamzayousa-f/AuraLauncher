import 'package:aura/core/services/launcher_service.dart';
import 'package:aura/core/services/usage_service.dart';
import 'package:aura/features/search/presentation/search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Wallpaper State Rules
  String _wallpaperType = 'asset';
  String _wallpaperPath = 'assets/wallpapers/default_noir.jpg';

  // Built-in presets matching your preference for high-contrast noir / cinematic tones
  final List<Map<String, String>> _presets = [
    {'name': 'Deep Noir', 'path': 'assets/wallpapers/default_noir.jpg'},
    {'name': 'Cyber Punk', 'path': 'assets/wallpapers/cyber_cinematic.jpg'},
    {
      'name': 'Editorial Minimal',
      'path': 'assets/wallpapers/editorial_mono.jpg',
    },
  ];

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
        orElse: () => {'name': 'App', 'package': pkg},
      );
      temporaryPinsList.add({'name': match['name']!, 'package': pkg});
    }

    setState(() {
      _usageStats = stats;
      _pinnedAppsList = temporaryPinsList;
      _wallpaperType = prefs.getString('wallpaper_type') ?? 'asset';
      _wallpaperPath =
          prefs.getString('wallpaper_path') ??
          'assets/wallpapers/default_noir.jpg';
    });
  }

  Future<void> _selectPresetWallpaper(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallpaper_type', 'asset');
    await prefs.setString('wallpaper_path', path);
    setState(() {
      _wallpaperType = 'asset';
      _wallpaperPath = path;
    });
    Navigator.pop(context);
  }

  Future<void> _pickGalleryWallpaper() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallpaper_type', 'file');
      await prefs.setString('wallpaper_path', image.path);
      setState(() {
        _wallpaperType = 'file';
        _wallpaperPath = image.path;
      });
      if (mounted) Navigator.pop(context);
    }
  }

  void _showWallpaperMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (context) {
        return GlassTheme.buildGlassPanel(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WALLPAPER PICKER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Trigger block to browse device gallery contents
                    GestureDetector(
                      onTap: _pickGalleryWallpaper,
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white70,
                              size: 28,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Render our beautiful cinematic presets
                    ..._presets.map((preset) {
                      final bool isSelected =
                          _wallpaperPath == preset['path'] &&
                          _wallpaperType == 'asset';
                      return GestureDetector(
                        onTap: () => _selectPresetWallpaper(preset['path']!),
                        child: Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.cyanAccent.withOpacity(0.6)
                                  : Colors.white10,
                              width: isSelected ? 2 : 1,
                            ),
                            color: Colors.black38,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white10,
                                ), // Placeholder color block
                              ),
                              Container(color: Colors.black45),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  preset['name']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
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
    return Stack(
      children: [
        WallpaperBackground(
          onLongPressHome: _showWallpaperMenu,
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
                const SizedBox(height: 20),
                GlassClock(),

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
                _loadHomeState();
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
