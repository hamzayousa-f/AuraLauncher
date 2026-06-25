import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/services/launcher_service.dart';

class NotificationFolderOverlay extends StatelessWidget {
  // Enforce strong typing using your project's model configuration
  final List<AuraAppModel> preloadedApps;

  const NotificationFolderOverlay({super.key, required this.preloadedApps});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Hero(
            tag: 'notification_folder_hub',
            child: Material(
              color: Colors.transparent,
              child: GlassTheme.buildGlassPanel(
                borderRadius: BorderRadius.circular(32),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Applications Hub",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: preloadedApps.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          final app = preloadedApps[index];
                          // Access the model properties directly via dot notation
                          final String appName = app.name;
                          final String pkgName = app.packageName;
                          final String base64Icon = app.iconBytes != null 
                              ? base64Encode(app.iconBytes!) 
                              : '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              LauncherService.launchApp(pkgName);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: base64Icon.isNotEmpty
                                      ? Image.memory(
                                          base64Decode(base64Icon),
                                          fit: BoxFit.contain,
                                        )
                                      : const Icon(Icons.apps_rounded, color: Colors.white30),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
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