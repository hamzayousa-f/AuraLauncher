import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/shared/tactile_button.dart';
import '../../../../core/services/launcher_service.dart';

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

    // Auto-focus the input instantly once the transition mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });

    _searchController.addListener(_handleSearchFiltering);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchFiltering);
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    // Premium structural matrix for desaturating app icons to blend elegantly
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
          color: Colors.black.withOpacity(0.4), // Ambient dark shade behind blur
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
              child: Column(
                children: [
                  // Upper Control Panel (SearchBar + Close Hook)
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
                      
                      // Tactile Close Button
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

                  // High-Performance Filtered Results Stream
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
                              physics: const ClampingScrollPhysics(), // Clean, jitter-free scroll bounds
                              itemBuilder: (context, index) {
                                final app = _filteredApps[index];
                                final bool hasIcon = app.iconBytes != null;

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
                                    TactileButton(
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
                                            // Soft Grayscale Anti-Aliased Icon Nest
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
                                            
                                            // Clean App Name Contrast
                                            Expanded(
                                              child: Text(
                                                app.name,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.85),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.1,
                                                ),
                                              ),
                                            ),
                                            
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: Colors.white.withOpacity(0.15),
                                              size: 16,
                                            ),
                                          ],
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
    );
  }
}