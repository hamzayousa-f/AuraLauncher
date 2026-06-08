import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/services/usage_service.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final List<AuraAppModel> preloadedApps;

  const SearchOverlay({
    super.key,
    required this.onClose,
    required this.preloadedApps,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<AuraAppModel> _filteredApps = [];
  Map<String, int> _usageStats = {};
  List<String> _pinnedPackages = [];

  @override
  void initState() {
    super.initState();
    _filteredApps = widget.preloadedApps;
    _loadLiveStatsAndPins();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  Future<void> _loadLiveStatsAndPins() async {
    final stats = await UsageService.getZenithUsageData();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _usageStats = stats;
      _pinnedPackages = prefs.getStringList('pinned_custom_apps') ?? [];
    });
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApps = widget.preloadedApps;
      } else {
        _filteredApps = widget.preloadedApps
            .where(
              (app) => app.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _togglePinApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    if (_pinnedPackages.contains(packageName)) {
      _pinnedPackages.remove(packageName);
    } else {
      if (_pinnedPackages.length >= 3) return;
      _pinnedPackages.add(packageName);
    }
    await prefs.setStringList('pinned_custom_apps', _pinnedPackages);
    setState(() {});
  }

  Color _getUsageColor(int minutes) {
    if (minutes >= 120) return Colors.redAccent;
    if (minutes >= 60) return Colors.yellowAccent;
    return Colors.white54;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const List<double> grayscaleMatrix = <double>[
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ), // Reduced vertical padding to prevent overflow
              child: Column(
                children: [
                  GlassTheme.buildGlassPanel(
                    borderRadius: BorderRadius.circular(30),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search applications...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: widget.onClose,
                        ),
                      ),
                      onChanged: _filterSearch,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: GlassTheme.buildGlassPanel(
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.all(4),
                      child: _filteredApps.isEmpty
                          ? const Center(
                              child: Text(
                                'No applications found',
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredApps.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final app = _filteredApps[index];
                                final bool isPinned = _pinnedPackages.contains(
                                  app.packageName,
                                );
                                final int minutes =
                                    _usageStats[app.packageName] ?? 0;
                                final String displayTime = minutes >= 60
                                    ? '${(minutes / 60).floor()}h ${minutes % 60}m'
                                    : '${minutes}m';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 1.0,
                                  ),
                                  // Fix ink splash exception: Provide a transparent material layer canvas
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      leading: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: app.iconBytes != null
                                            ? ColorFiltered(
                                                colorFilter:
                                                    const ColorFilter.matrix(
                                                      grayscaleMatrix,
                                                    ),
                                                child: Image.memory(
                                                  app.iconBytes!,
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.android,
                                                color: Colors.white60,
                                              ),
                                      ),
                                      title: Text(
                                        app.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isPinned)
                                            const Icon(
                                              Icons.push_pin_rounded,
                                              color: Colors.cyanAccent,
                                              size: 14,
                                            ),
                                          const SizedBox(width: 8),
                                          Text(
                                            displayTime,
                                            style: TextStyle(
                                              color: _getUsageColor(minutes),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onLongPress: () =>
                                          _togglePinApp(app.packageName),
                                      onTap: () {
                                        LauncherService.launchApp(
                                          app.packageName,
                                        );
                                        widget.onClose();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
