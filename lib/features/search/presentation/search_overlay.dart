import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/services/usage_service.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const SearchOverlay({super.key, required this.onClose});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, String>> _allApps = [];
  List<Map<String, String>> _filteredApps = [];
  Map<String, int> _usageStats = {};
  List<String> _pinnedPackages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicationsAndStats();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  Future<void> _loadApplicationsAndStats() async {
    final apps = await LauncherService.getInstalledApps();
    final stats = await UsageService.getZenithUsageData();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _allApps = apps;
      _filteredApps = apps;
      _usageStats = stats;
      _pinnedPackages = prefs.getStringList('pinned_custom_apps') ?? [];
      _isLoading = false;
    });
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApps = _allApps;
      } else {
        _filteredApps = _allApps
            .where(
              (app) => app['name']!.toLowerCase().contains(query.toLowerCase()),
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
                vertical: 16.0,
              ),
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
                  const SizedBox(height: 16),

                  Expanded(
                    child: GlassTheme.buildGlassPanel(
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.all(8),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                              ),
                            )
                          : _filteredApps.isEmpty
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
                                final String pkg = app['package'] ?? '';
                                final String base64Icon = app['icon'] ?? '';
                                final bool isPinned = _pinnedPackages.contains(
                                  pkg,
                                );

                                final int minutes = _usageStats[pkg] ?? 0;
                                final Color timeColor = _getUsageColor(minutes);
                                final String displayTime = minutes >= 60
                                    ? '${(minutes / 60).floor()}h ${minutes % 60}m'
                                    : '${minutes}m';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                  ),
                                  child: ListTile(
                                    leading: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: base64Icon.isNotEmpty
                                          ? Image.memory(
                                              base64Decode(base64Icon),
                                              fit: BoxFit.contain,
                                            )
                                          : const Icon(
                                              Icons.android,
                                              color: Colors.white60,
                                            ),
                                    ),
                                    title: Text(
                                      app['name']!,
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
                                            color: timeColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onLongPress: () => _togglePinApp(pkg),
                                    onTap: () {
                                      LauncherService.launchApp(pkg);
                                      widget.onClose();
                                    },
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
