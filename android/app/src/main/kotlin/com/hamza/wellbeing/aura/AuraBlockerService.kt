package com.hamza.wellbeing.aura

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class AuraBlockerService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Intercept whenever a new window state or application changes focus
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val launchedPackage = event.packageName?.toString() ?: return

            // Don't intercept Aura itself
            if (launchedPackage == packageName) return

                // Pull shared preferences synchronized from the Flutter MERN/Sync engine
                val nativePrefs = getSharedPreferences("com.hamza.wellbeing.aura.BLOCKER_PREFS", Context.MODE_PRIVATE)

                val isMasterFocusActive = nativePrefs.getBoolean("master_focus_mode_active", false)
                val isAppRestricted = nativePrefs.getBoolean("block_pkg_$launchedPackage", false)

                // If master focus is on, or this specific app is marked restricted
                if (isMasterFocusActive || isAppRestricted) {

                    // Strike back down by instantly forcing MainActivity to the absolute foreground
                    val blockIntent = Intent(this, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        category = Intent.CATEGORY_LAUNCHER
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                        // Pass the blocked package information down to the overlay pipeline
                        putExtra("BLOCKED_PACKAGE_EXTRA", launchedPackage)
                    }
                    startActivity(blockIntent)
                }
        }
    }

    override fun onInterrupt() {
        // Graceful handling if the OS interrupts the accessibility node connection
    }
}
