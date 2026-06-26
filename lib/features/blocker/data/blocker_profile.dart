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
}