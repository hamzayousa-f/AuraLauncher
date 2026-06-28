package com.hamza.wellbeing.aura

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AuraBlockerService : AccessibilityService() {

    private val mainThreadHandler = Handler(Looper.getMainLooper())

    // CRITICAL: This companion object allows MainActivity to access these variables
    companion object {
        var temporaryBypassPackage: String? = null
        var bypassTimestamp: Long = 0L
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val launchedPackage = event.packageName?.toString() ?: return

            // Ignore system UI and Aura itself
            if (launchedPackage == packageName ||
                launchedPackage.contains("com.android.systemui") ||
                launchedPackage.contains("launcher")) return

                // CHECK: Is there an active bypass for this package?
                val currentTime = System.currentTimeMillis()
                if (launchedPackage == temporaryBypassPackage && (currentTime - bypassTimestamp) < 10000) {
                    Log.d("AuraBlocker", "Bypass active for: $launchedPackage")
                    return
                }

                val prefs = getSharedPreferences("com.hamza.wellbeing.aura.BLOCKER_PREFS", Context.MODE_PRIVATE)
                val isMasterFocus = prefs.getBoolean("master_focus_mode_active", false)
                val isRestricted = prefs.getBoolean("block_pkg_$launchedPackage", false)
                val isLimitReached = prefs.getBoolean("limit_reached_$launchedPackage", false)

                if (isMasterFocus || isRestricted || isLimitReached) {
                    Log.d("AuraBlocker", "Intercepting: $launchedPackage")

                    val blockIntent = Intent(this, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_NO_ANIMATION or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT

                        putExtra("BLOCKED_PACKAGE_EXTRA", launchedPackage)
                        putExtra("LIMIT_REACHED_EXTRA", isLimitReached)
                    }
                    startActivity(blockIntent)

                    mainThreadHandler.postDelayed({
                        performGlobalAction(GLOBAL_ACTION_HOME)
                    }, 80)
                }
        }
    }

    override fun onInterrupt() {}
}
