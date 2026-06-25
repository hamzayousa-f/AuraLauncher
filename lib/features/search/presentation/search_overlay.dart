import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/shared/tactile_button.dart';
import '../../../../core/services/launcher_service.dart';
import '../../../../core/services/usage_service.dart';

class SearchOverlay extends StatefulWidget {
  final List<AuraAppModel> preloadedApps;
  final VoidCallback onClose;

  const SearchOverlay({
    super.key,
    required this.preloadedApps,
    required this.onClose,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<AuraAppModel> _filteredApps = [];
  Map<String, int> _searchUsageStats = {};
  List<String> _currentlyPinnedPackages = [];

  @override
  void initState() {
    super.initState();
    _filteredApps = widget.preloadedApps;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08), 
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });

    _searchController.addListener(_handleSearchFiltering);
    _loadSearchTelemetryAndPins();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchFiltering);
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Extracts system runtime usage data and pins to render context inline
  Future<void> _loadSearchTelemetryAndPins() async {
    try {
      final stats = await UsageService.getZenithUsageData();
      final prefs = await SharedPreferences.getInstance();
      final pinned = prefs.getStringList('pinned_custom_apps') ?? [];
      
      setState(() {
        _searchUsageStats = stats;
        _currentlyPinnedPackages = pinned;
      });
    } catch (_) {}
  }

  /// Toggles the focus pinning structure via inline haptic pop updates
  Future<void> _togglePinState(String packageName, String appName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinned = prefs.getStringList('pinned_custom_apps') ?? [];
    
    bool wasPinned = pinned.contains(packageName);
    if (wasPinned) {
      pinned.remove(packageName);
    } else {
      pinned.add(packageName);
    }
    
    await prefs.setStringList('pinned_custom_apps', pinned);
    
    setState(() {
      _currentlyPinnedPackages = pinned;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.white10,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            wasPinned ? 'Removed $appName from focus layout' : 'Pinned $appName to workspace home',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleSearchFiltering() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredApps = widget.preloadedApps;
      } else {
        _filteredApps = widget.preloadedApps
            .where((app) => app.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _handleDismissal() async {
    _focusNode.unfocus();
    await _animationController.reverse();
    widget.onClose();
  }

  Color _getUsageColor(int minutes) {
    if (minutes >= 120) return Colors.redAccent.withOpacity(0.85);
    if (minutes >= 60) return Colors.amberAccent.withOpacity(0.85);
    return Colors.white38;
  }

  @override
  Widget build(BuildContext context) {
    const List<double> grayscaleMatrix = <double>[
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0,    0,    0,    0.5, 0, 
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: Colors.black.withOpacity(0.4), // Stays full-screen as backdrop
          child: SafeArea(
            bottom: false,
            child: Padding(
              // THIS WRAPPER CAPTURES THE KEYBOARD HEIGHT AND DYNAMICALLY SHRINKS THE SCROLLABLE SPACE
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GlassTheme.buildGlassPanel(
                            borderRadius: BorderRadius.circular(24),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                              ),
                              cursorColor: Colors.cyanAccent.withOpacity(0.6),
                              cursorWidth: 1.5,
                              decoration: InputDecoration(
                                hintText: 'Type to scan systems...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TactileButton(
                          onTap: _handleDismissal,
                          borderRadius: BorderRadius.circular(20),
                          child: GlassTheme.buildGlassPanel(
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.all(12.0),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: GlassTheme.buildGlassPanel(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: _filteredApps.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching apps found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.2),
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredApps.length,
                                padding: const EdgeInsets.only(top: 8, bottom: 32),
                                physics: const ClampingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final app = _filteredApps[index];
                                  final bool hasIcon = app.iconBytes != null;
                                  final bool isPinned = _currentlyPinnedPackages.contains(app.packageName);
                                  
                                  final int minutes = _searchUsageStats[app.packageName] ?? 0;
                                  final Color usageColor = _getUsageColor(minutes);
                                  final String displayTime = minutes >= 60 
                                      ? '${(minutes / 60).floor()}h ${minutes % 60}m'
                                      : '${minutes}m';

                                  return Column(
                                    children: [
                                      if (index > 0)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                          child: Divider(
                                            color: Colors.white.withOpacity(0.03),
                                            height: 1,
                                          ),
                                        ),
                                      GestureDetector(
                                        onLongPress: () {
                                          HapticFeedback.heavyImpact();
                                          _togglePinState(app.packageName, app.name);
                                        },
                                        child: TactileButton(
                                          onTap: () {
                                            _focusNode.unfocus();
                                            LauncherService.launchApp(app.packageName);
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14.0,
                                              vertical: 12.0,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: hasIcon
                                                      ? ColorFiltered(
                                                          colorFilter: const ColorFilter.matrix(grayscaleMatrix),
                                                          child: Image.memory(
                                                            app.iconBytes!,
                                                            fit: BoxFit.contain,
                                                            filterQuality: FilterQuality.medium,
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.apps_rounded,
                                                          color: Colors.white.withOpacity(0.3),
                                                          size: 18,
                                                      ),
                                                ),
                                                const SizedBox(width: 16),
                                                
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          app.name,
                                                          style: TextStyle(
                                                            color: Colors.white.withOpacity(0.85),
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w400,
                                                            letterSpacing: -0.1,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (isPinned) ...[
                                                        const SizedBox(width: 8),
                                                        Icon(
                                                          Icons.push_pin_rounded,
                                                          color: Colors.cyanAccent.withOpacity(0.6),
                                                          size: 11,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                
                                                Text(
                                                  displayTime,
                                                  style: TextStyle(
                                                    color: usageColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Colors.white.withOpacity(0.15),
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}