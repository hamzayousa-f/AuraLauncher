import 'package:flutter/material.dart';

class BlockerProfile {
  final String packageId;
  final String readableName;
  final IconData visualIcon;
  bool isRestricted;
  int allocationLimitMinutes;
  int currentAccumulatedMinutes;
  bool IsSecurityEnforced;
  String? accessPinCode;

  BlockerProfile({
    required this.packageId,
    required this.readableName,
    required this.visualIcon,
    this.isRestricted = false,
    this.allocationLimitMinutes = 30,
    this.currentAccumulatedMinutes = 0,
    this.IsSecurityEnforced = false,
    this.accessPinCode,
  });

  bool get hasExceededLimit => currentAccumulatedMinutes >= allocationLimitMinutes;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'packageId': packageId,
      'readableName': readableName,
      'iconCodePoint': visualIcon.codePoint,
      'isRestricted': isRestricted,
      'allocationLimitMinutes': allocationLimitMinutes,
      'currentAccumulatedMinutes': currentAccumulatedMinutes,
      'IsSecurityEnforced': IsSecurityEnforced,
      'accessPinCode': accessPinCode,
    };
  }

  factory BlockerProfile.fromJson(Map<String, dynamic> json) {
    return BlockerProfile(
      packageId: json['packageId'] ?? '',
      readableName: json['readableName'] ?? 'Unknown',
      visualIcon: IconData(
        json['iconCodePoint'] ?? Icons.apps.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      isRestricted: json['isRestricted'] ?? false,
      allocationLimitMinutes: json['allocationLimitMinutes'] ?? 30,
      currentAccumulatedMinutes: json['currentAccumulatedMinutes'] ?? 0,
      IsSecurityEnforced: json['IsSecurityEnforced'] ?? false,
      accessPinCode: json['accessPinCode'],
    );
  }
}