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

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val launchedPackage = event.packageName?.toString() ?: return

            // Ignore system UI and Aura itself
            if (launchedPackage == packageName ||
                launchedPackage.contains("com.android.systemui") ||
                launchedPackage.contains("launcher")) return

                val prefs = getSharedPreferences("com.hamza.wellbeing.aura.BLOCKER_PREFS", Context.MODE_PRIVATE)
                val isMasterFocus = prefs.getBoolean("master_focus_mode_active", false)
                val isRestricted = prefs.getBoolean("block_pkg_$launchedPackage", false)

                // Fetch the specific daily limit status flag managed by your Flutter background tracking
                val isLimitReached = prefs.getBoolean("limit_reached_$launchedPackage", false)

                // Intercept if master focus is on, if the app is restricted, or if it hit its daily limit
                if (isMasterFocus || isRestricted || isLimitReached) {
                    Log.d("AuraBlocker", "Intercepted: $launchedPackage | Limit Reached: $isLimitReached")

                    // 1. Prepare the intent for your warm Flutter MainActivity
                    val blockIntent = Intent(this, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_NO_ANIMATION or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT

                        putExtra("BLOCKED_PACKAGE_EXTRA", launchedPackage)
                        // Pass this extra flag so Flutter knows which state animation to render
                        putExtra("LIMIT_REACHED_EXTRA", isLimitReached)
                    }
                    startActivity(blockIntent)

                    // 2. Clear foreground app context cleanly behind the warm fluid layout
                    mainThreadHandler.postDelayed({
                        performGlobalAction(GLOBAL_ACTION_HOME)
                    }, 80)
                }
        }
    }

    override fun onInterrupt() {}
}
