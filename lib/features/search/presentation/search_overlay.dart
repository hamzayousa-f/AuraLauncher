import 'dart:convert';
import 'package:aura/features/blocker/data/blocker_service.dart';
import 'package:aura/features/blocker/presentation/views/fluid_friction_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/shared/tactile_button.dart';
import '../../../../core/services/launcher_service.dart';
import '../../../../core/services/usage_service.dart';

// Assuming standard mock or explicit model location format


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
  final ScrollController _scrollController = ScrollController();
  
  List<AuraAppModel> _filteredApps = [];
  Map<String, int> _searchUsageStats = {};
  List<String> _currentlyPinnedPackages = [];
  String _lastQuery = '';

  // Cache for computed values
  final Map<String, _AppDisplayData> _displayDataCache = {};

  @override
  void initState() {
    super.initState();
    _filteredApps = widget.preloadedApps;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.06), 
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _loadSearchTelemetryAndPins();
      }
    });

    _searchController.addListener(_handleSearchFiltering);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchFiltering);
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _displayDataCache.clear();
    super.dispose();
  }

  Future<void> _loadSearchTelemetryAndPins() async {
    try {
      final results = await Future.wait([
        UsageService.getZenithUsageData(),
        SharedPreferences.getInstance(),
      ]);
      
      final stats = results[0] as Map<String, int>;
      final prefs = results[1] as SharedPreferences;
      final pinned = prefs.getStringList('pinned_custom_apps') ?? [];
      
      if (mounted) {
        setState(() {
          _searchUsageStats = stats;
          _currentlyPinnedPackages = pinned;
          _displayDataCache.clear();
        });
      }
    } catch (_) {}
  }

  Future<void> _togglePinState(String packageName, String appName) async {
    HapticFeedback.mediumImpact();
    
    final prefs = await SharedPreferences.getInstance();
    List<String> pinned = List<String>.from(prefs.getStringList('pinned_custom_apps') ?? []);
    
    bool wasPinned = pinned.contains(packageName);
    if (wasPinned) {
      pinned.remove(packageName);
    } else {
      pinned.add(packageName);
    }
    
    await prefs.setStringList('pinned_custom_apps', pinned);
    
    if (mounted) {
      setState(() {
        _currentlyPinnedPackages = pinned;
        _displayDataCache.remove(packageName);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(
                wasPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: Colors.cyanAccent.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  wasPinned ? 'Unpinned $appName' : 'Pinned $appName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 1800),
        ),
      );
    }
  }

  void _handleSearchFiltering() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      if (query.isEmpty) {
        _filteredApps = widget.preloadedApps;
      } else {
        _filteredApps = widget.preloadedApps
            .where((app) => app.name.toLowerCase().contains(query))
            .toList();
      }
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _handleDismissal() async {
    _focusNode.unfocus();
    await _animationController.reverse();
    widget.onClose();
  }

  _AppDisplayData _getDisplayData(AuraAppModel app) {
    if (_displayDataCache.containsKey(app.packageName)) {
      final cached = _displayDataCache[app.packageName]!;
      return cached.copyWith(
        isPinned: _currentlyPinnedPackages.contains(app.packageName),
      );
    }

    final int minutes = _searchUsageStats[app.packageName] ?? 0;
    final Color usageColor = _getUsageColor(minutes);
    final String displayTime = _formatTime(minutes);
    final bool isPinned = _currentlyPinnedPackages.contains(app.packageName);

    final data = _AppDisplayData(
      usageColor: usageColor,
      displayTime: displayTime,
      isPinned: isPinned,
    );

    _displayDataCache[app.packageName] = data;
    return data;
  }

  Color _getUsageColor(int minutes) {
    if (minutes >= 120) return const Color(0xFFFF6B6B);
    if (minutes >= 60) return const Color(0xFFFFD93D);
    if (minutes >= 30) return const Color(0xFF6BCB77);
    return Colors.white24;
  }

  String _formatTime(int minutes) {
    if (minutes == 0) return '0m';
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    const List<double> grayscaleMatrix = <double>[
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0,    0,    0,    0.52, 0, 
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 0.0),
                child: Column(
                  children: [
                    // Search Bar Block
                    Row(
                      children: [
                        Expanded(
                          child: GlassTheme.buildGlassPanel(
                            borderRadius: BorderRadius.circular(26),
                            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 3.0),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.15,
                              ),
                              cursorColor: Colors.cyanAccent.withOpacity(0.7),
                              cursorWidth: 1.8,
                              cursorRadius: const Radius.circular(2),
                              decoration: InputDecoration(
                                hintText: 'Search apps...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.28),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withOpacity(0.35),
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _focusNode.requestFocus();
                                        },
                                        child: Icon(
                                          Icons.clear_rounded,
                                          color: Colors.white.withOpacity(0.35),
                                          size: 18,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TactileButton(
                          onTap: _handleDismissal,
                          borderRadius: BorderRadius.circular(22),
                          child: GlassTheme.buildGlassPanel(
                            borderRadius: BorderRadius.circular(22),
                            padding: const EdgeInsets.all(13.0),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Results Stats Descriptor
                    if (_filteredApps.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                        child: Row(
                          children: [
                            Text(
                              '${_filteredApps.length} ${_filteredApps.length == 1 ? 'app' : 'apps'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white.withOpacity(0.25),
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Long press to pin',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),

                    // App Core List Panel Container
                    Expanded(
                      child: GlassTheme.buildGlassPanel(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        child: _filteredApps.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      color: Colors.white.withOpacity(0.15),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No matching apps found',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.25),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Try a different search term',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.15),
                                        fontSize: 12,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: _filteredApps.length,
                                // Enforcing precise item bounding size
                                itemExtent: 56.0,
                                padding: const EdgeInsets.only(top: 6, bottom: 28),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final app = _filteredApps[index];
                                  return _AppListItem(
                                    key: ValueKey(app.packageName),
                                    app: app,
                                    displayData: _getDisplayData(app),
                                    grayscaleMatrix: grayscaleMatrix,
                                    showDivider: index > 0,
                                    onTap: () async {
                                      _focusNode.unfocus();
final result = await LauncherService.launchApp(app.packageName);

if (result.blocked && mounted) {
  final profile = BlockerService.instance.getProfileForPackage(app.packageName);
  
  if (profile != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FluidFrictionOverlay(
          profile: profile,
          onOverrideUnlocked: () async {
            profile.currentAccumulatedMinutes = 0;
            await BlockerService.instance.updateProfile(profile);
          },
        ),
      ),
    );
  }
}                                    },
                                    onLongPress: () {
                                      _togglePinState(app.packageName, app.name);
                                    },
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

class _AppListItem extends StatelessWidget {
  final AuraAppModel app;
  final _AppDisplayData displayData;
  final List<double> grayscaleMatrix;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppListItem({
    super.key,
    required this.app,
    required this.displayData,
    required this.grayscaleMatrix,
    required this.showDivider,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasIcon = app.iconBytes != null;

    // FIX: Enclosed layout elements within a Stack to cleanly draw the top border divider 
    // without scaling or overflowing the mandatory 56.0 tracking bounds.
    return Stack(
      children: [
        if (showDivider)
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Divider(
              color: Colors.white.withOpacity(0.04),
              height: 0.5,
              thickness: 0.5,
            ),
          ),
        GestureDetector(
          onLongPress: onLongPress,
          child: TactileButton(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  // App Icon Panel
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: hasIcon
                        ? ColorFiltered(
                            colorFilter: ColorFilter.matrix(grayscaleMatrix),
                            child: Image.memory(
                              app.iconBytes!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              gaplessPlayback: true,
                            ),
                          )
                        : Icon(
                            Icons.apps_rounded,
                            color: Colors.white.withOpacity(0.3),
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Text Context & Optional Pin Indicator
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            app.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.15,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (displayData.isPinned) ...[
                          const SizedBox(width: 7),
                          Icon(
                            Icons.push_pin,
                            color: Colors.cyanAccent.withOpacity(0.7),
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Metric Telemetry Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: displayData.usageColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayData.displayTime,
                      style: TextStyle(
                        color: displayData.usageColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.18),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppDisplayData {
  final Color usageColor;
  final String displayTime;
  final bool isPinned;

  const _AppDisplayData({
    required this.usageColor,
    required this.displayTime,
    required this.isPinned,
  });

  _AppDisplayData copyWith({
    Color? usageColor,
    String? displayTime,
    bool? isPinned,
  }) {
    return _AppDisplayData(
      usageColor: usageColor ?? this.usageColor,
      displayTime: displayTime ?? this.displayTime,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}