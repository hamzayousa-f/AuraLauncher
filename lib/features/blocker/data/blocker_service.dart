import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocker_profile.dart';

class BlockerService {
  static final BlockerService instance = BlockerService._internal();
  BlockerService._internal();

  List<BlockerProfile> profiles = [];
  bool isMasterFocusModeActive = false;

  static const String _profilesKey = 'blocker_profiles_v1';
  static const String _masterSwitchKey = 'master_focus_mode';

  Future<void> fetchInstalledApps() async {
    // Prevent re-fetching if already loaded
    if (profiles.isNotEmpty) return;

    // Load saved profiles first
    await _loadProfilesFromDisk();

    List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeSystemApps: true);
    
    // Create a map of existing profiles by packageId for quick lookup
    Map<String, BlockerProfile> existingProfilesMap = {
      for (var profile in profiles) profile.packageId: profile
    };

    // Update profiles list with installed apps
    profiles = apps.map((app) {
      final packageName = app.packageName ?? '';
      
      // If profile already exists, keep its settings
      if (existingProfilesMap.containsKey(packageName)) {
        return existingProfilesMap[packageName]!;
      }
      
      // Otherwise create new profile
      return BlockerProfile(
        packageId: packageName,
        readableName: app.name ?? 'Unknown',
        visualIcon: Icons.apps,
      );
    }).toList();

    // Save after fetching
    await saveProfiles();
  }

  /// Check if an app is blocked and should show intervention
  bool shouldBlockApp(String packageName) {
    if (!isMasterFocusModeActive) return false;

    try {
      final profile = profiles.firstWhere(
        (p) => p.packageId == packageName,
      );

      return profile.isRestricted;
    } catch (_) {
      // No profile found for this app
      return false;
    }
  }

  /// Get profile for a specific package
  BlockerProfile? getProfileForPackage(String packageName) {
    try {
      return profiles.firstWhere((p) => p.packageId == packageName);
    } catch (_) {
      return null;
    }
  }

  /// Save profiles to disk
  Future<void> saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save master switch state
      await prefs.setBool(_masterSwitchKey, isMasterFocusModeActive);
      
      // Convert profiles to JSON
      final List<Map<String, dynamic>> jsonList = profiles.map((p) => p.toJson()).toList();
      final String jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_profilesKey, jsonString);
    } catch (e) {
      print('Failed to save blocker profiles: $e');
    }
  }

  /// Load profiles from disk
  Future<void> _loadProfilesFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load master switch state
      isMasterFocusModeActive = prefs.getBool(_masterSwitchKey) ?? false;
      
      // Load profiles
      final String? jsonString = prefs.getString(_profilesKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        profiles = jsonList.map((json) => BlockerProfile.fromJson(json)).toList();
      }
    } catch (e) {
      print('Failed to load blocker profiles: $e');
    }
  }

  /// Update master focus mode and save
  Future<void> setMasterFocusMode(bool isActive) async {
    isMasterFocusModeActive = isActive;
    await saveProfiles();
  }

  /// Update a profile and save
  Future<void> updateProfile(BlockerProfile profile) async {
    final index = profiles.indexWhere((p) => p.packageId == profile.packageId);
    if (index != -1) {
      profiles[index] = profile;
      await saveProfiles();
    } else {
      // If not found, add it
      profiles.add(profile);
      await saveProfiles();
    }
  }
}