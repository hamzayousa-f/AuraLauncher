package com.hamza.wellbeing.aura

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AuraBlockerService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val launchedPackage = event.packageName?.toString() ?: return

            // Ignore system UI and Aura itself
            if (launchedPackage == packageName ||
                launchedPackage.contains("com.android.systemui") ||
                launchedPackage.contains("launcher")) return

                // Check our shared sync rules
                val prefs = getSharedPreferences("com.hamza.wellbeing.aura.BLOCKER_PREFS", Context.MODE_PRIVATE)
                val isMasterFocus = prefs.getBoolean("master_focus_mode_active", false)
                val isRestricted = prefs.getBoolean("block_pkg_\$launchedPackage", false)

                if (isMasterFocus || isRestricted) {
                    Log.d("AuraBlocker", "Intercepted restricted app: \$launchedPackage")

                    // Route to MainActivity smoothly
                    val blockIntent = Intent(this, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                        putExtra("BLOCKED_PACKAGE_EXTRA", launchedPackage)
                    }
                    startActivity(blockIntent)
                }
        }
    }

    override fun onInterrupt() {}
}
