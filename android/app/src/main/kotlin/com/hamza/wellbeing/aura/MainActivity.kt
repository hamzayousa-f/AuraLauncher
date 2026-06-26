package com.hamza.wellbeing.aura

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.BatteryManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar
import android.app.usage.UsageEvents
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import java.lang.reflect.Method
import java.util.Locale
import org.json.JSONArray

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hamza.wellbeing.aura/launcher"
    private val SYNC_CHANNEL = "com.aura.blocker/sync" // Match the Dart channel exactly
    private var packageRemovedReceiver: BroadcastReceiver? = null

        override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
            super.configureFlutterEngine(flutterEngine)

            registerUninstallReceiver()

            // 1. Existing Launcher Channel Configuration
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchSystemApp" -> {
                        val packageName = call.argument<String>("packageName") ?: ""
                        if (packageName.isNotEmpty() && executeLaunchIntent(packageName)) {
                            result.success(true)
                        } else {
                            result.error("LAUNCH_FAILED", "Could not execute intent", null)
                        }
                    }
                    "getInstalledApps" -> {
                        result.success(fetchInstalledApplications())
                    }
                    "checkUsagePermission" -> {
                        result.success(isUsageStatsPermissionGranted())
                    }
                    "openUsageSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                        result.success(true)
                    }
                    "getAppUsageStats", "getNativeScreenTime", "getZenithUsageData" -> {
                        val startTime = call.argument<Long>("startTime") ?: Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }.timeInMillis

                        val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                        result.success(getDeviceScreenTimeMinutes(startTime, endTime))
                    }
                    "getTotalSystemScreenTime" -> {
                        result.success(computeAbsoluteScreenTimeMinutes())
                    }
                    "expandQuickSettings" -> {
                        expandNotificationPanel()
                        result.success(null)
                    }
                    "turnOffScreen" -> {
                        triggerScreenLock()
                        result.success(null)
                    }
                    "getBatteryStatus" -> {
                        val batteryStatus: Intent? = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                        val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                        var batteryPct = if (level >= 0 && scale > 0) (level * 100 / scale.toFloat()).toInt() else -1
                        var isCharging = false

                        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                        if (status != -1) {
                            isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                            status == BatteryManager.BATTERY_STATUS_FULL
                        }

                        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                        if (batteryPct == -1) {
                            batteryPct = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                        }
                        if (status == -1) {
                            isCharging = bm.isCharging
                        }

                        val data = mapOf(
                            "level" to if (batteryPct in 0..100) batteryPct else 85,
                                         "isCharging" to isCharging
                        )
                        result.success(data)
                    }
                    "getNotificationCount" -> {
                        result.success(NotificationService.getActiveNotificationsCount())
                    }
                    "getActiveNotifications" -> {
                        result.success(NotificationService.getActiveNotificationsData())
                    }
                    "checkNotificationPermission" -> {
                        result.success(isNotificationServiceEnabled())
                    }
                    "openNotificationSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

            // 2. NEW: Native Blocker Sync Mechanism
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYNC_CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "syncRules") {
                    try {
                        val masterFocusMode = call.argument<Boolean>("masterFocusMode") ?: false
                        val restrictions = call.argument<Map<String, Boolean>>("restrictions") ?: emptyMap()

                        // Dump primitives into native SharedPreferences so the accessibility/overlay engine can access it instantly
                        val nativePrefs = getSharedPreferences("com.hamza.wellbeing.aura.BLOCKER_PREFS", Context.MODE_PRIVATE)
                        val editor = nativePrefs.edit()

                        editor.putBoolean("master_focus_mode_active", masterFocusMode)

                        // Flatten app profiles to individual access keys
                        for ((pkg, isRestricted) in restrictions) {
                            editor.putBoolean("block_pkg_$pkg", isRestricted)
                        }
                        editor.apply()

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SYNC_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
        }

        private fun registerUninstallReceiver() {
            if (packageRemovedReceiver != null) return

                packageRemovedReceiver = object : BroadcastReceiver() {
                    override fun onReceive(context: Context?, intent: Intent?) {
                        if (intent?.action == Intent.ACTION_PACKAGE_FULLY_REMOVED) {
                            val dataUri = intent.data
                            val packageName = dataUri?.schemeSpecificPart ?: return
                            cleanUpNativePinnedApp(packageName)
                        }
                    }
                }

                val filter = IntentFilter().apply {
                    addAction(Intent.ACTION_PACKAGE_FULLY_REMOVED)
                    addDataScheme("package")
                }
                registerReceiver(packageRemovedReceiver, filter)
        }

        private fun cleanUpNativePinnedApp(uninstalledPackage: String) {
            try {
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jsonKey = "flutter.pinned_custom_apps"

                val savedRawString = prefs.getString(jsonKey, null) ?: return
                val jsonArray = JSONArray(savedRawString)
                val updatedList = mutableListOf<String>()
                var dataChanged = false

                for (i in 0 until jsonArray.length()) {
                    val pkgName = jsonArray.getString(i)
                    if (pkgName != uninstalledPackage) {
                        updatedList.add(pkgName)
                    } else {
                        dataChanged = true
                    }
                }

                if (dataChanged) {
                    val outputJsonArray = JSONArray(updatedList)
                    prefs.edit().putString(jsonKey, outputJsonArray.toString()).apply()
                }
            } catch (e: Exception) {
                // Safe fallback bounds
            }
        }

        override fun onDestroy() {
            packageRemovedReceiver?.let {
                unregisterReceiver(it)
                packageRemovedReceiver = null
            }
            super.onDestroy()
        }

        private fun isUsageStatsPermissionGranted(): Boolean {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
            return mode == AppOpsManager.MODE_ALLOWED
        }

        private fun getDeviceScreenTimeMinutes(startTimeFromFlutter: Long, endTimeFromFlutter: Long): Map<String, Int> {
            val statsMap = mutableMapOf<String, Int>()
            if (!isUsageStatsPermissionGranted()) return statsMap

                val calendar = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val strictMidnightToday = calendar.timeInMillis
                val strictNow = System.currentTimeMillis()

                val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val events = usageStatsManager.queryEvents(strictMidnightToday, strictNow)
                val event = UsageEvents.Event()

                val appAccumulatedMs = HashMap<String, Long>()

                var lastEventTime: Long = 0
                var currentActivePackage: String? = null

                while (events.hasNextEvent()) {
                    events.getNextEvent(event)
                    val pkgName = event.packageName ?: continue

                    if (pkgName == packageName) continue

                        if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                            if (currentActivePackage != null && lastEventTime > 0 && event.timeStamp > lastEventTime) {
                                val duration = event.timeStamp - lastEventTime
                                if (duration in 1..86400000L) {
                                    val totalMs = appAccumulatedMs[currentActivePackage] ?: 0L
                                    appAccumulatedMs[currentActivePackage!!] = totalMs + duration
                                }
                            }
                            currentActivePackage = pkgName
                            lastEventTime = event.timeStamp
                        }
                        else if (event.eventType == UsageEvents.Event.ACTIVITY_PAUSED ||
                            event.eventType == UsageEvents.Event.ACTIVITY_STOPPED) {

                            if (currentActivePackage == pkgName && lastEventTime > 0 && event.timeStamp > lastEventTime) {
                                val duration = event.timeStamp - lastEventTime
                                if (duration in 1..86400000L) {
                                    val totalMs = appAccumulatedMs[pkgName] ?: 0L
                                    appAccumulatedMs[pkgName] = totalMs + duration
                                }
                                currentActivePackage = null
                                lastEventTime = 0
                            }
                            }
                }

                if (currentActivePackage != null && lastEventTime > 0 && strictNow > lastEventTime) {
                    val trailingDuration = strictNow - lastEventTime
                    if (trailingDuration in 1..86400000L) {
                        val totalMs = appAccumulatedMs[currentActivePackage!!] ?: 0L
                        appAccumulatedMs[currentActivePackage!!] = totalMs + trailingDuration
                    }
                }

                for ((pkg, totalMs) in appAccumulatedMs) {
                    val minutes = (totalMs / (1000 * 60)).toInt()
                    if (minutes > 0) {
                        statsMap[pkg] = minutes
                    }
                }

                return statsMap
        }

        private fun computeAbsoluteScreenTimeMinutes(): Int {
            if (!isUsageStatsPermissionGranted()) return 0

                val calendar = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val midnightToday = calendar.timeInMillis
                val now = System.currentTimeMillis()

                val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val events = usageStatsManager.queryEvents(midnightToday, now)
                val event = UsageEvents.Event()

                var totalForegroundMs: Long = 0
                var lastEventTime: Long = 0
                var currentActivePackage: String? = null

                while (events.hasNextEvent()) {
                    events.getNextEvent(event)

                    if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                        if (currentActivePackage != null && lastEventTime > 0) {
                            val duration = event.timeStamp - lastEventTime
                            if (duration > 0 && currentActivePackage != packageName) {
                                totalForegroundMs += duration
                            }
                        }
                        currentActivePackage = event.packageName
                        lastEventTime = event.timeStamp
                    } else if (event.eventType == UsageEvents.Event.ACTIVITY_PAUSED ||
                        event.eventType == UsageEvents.Event.KEYGUARD_HIDDEN) {
                        if (currentActivePackage == event.packageName && lastEventTime > 0) {
                            val duration = event.timeStamp - lastEventTime
                            if (duration > 0 && currentActivePackage != packageName) {
                                totalForegroundMs += duration
                            }
                            currentActivePackage = null
                            lastEventTime = 0
                        }
                        }
                }

                if (currentActivePackage != null && lastEventTime > 0 && currentActivePackage != packageName) {
                    val trailingDuration = now - lastEventTime
                    if (trailingDuration > 0) {
                        totalForegroundMs += trailingDuration
                    }
                }

                return (totalForegroundMs / (1000 * 60)).toInt().coerceAtLeast(0)
        }

        private fun expandNotificationPanel() {
            try {
                val statusBarService = getSystemService("statusbar")
                val statusBarManagerClass = Class.forName("android.app.StatusBarManager")
                val method: Method = statusBarManagerClass.getMethod("expandNotificationsPanel")
                method.invoke(statusBarService)
            } catch (e: Exception) {
                Log.e("AuraLauncher", "Failed to expand notification panel using reflection", e)
            }
        }

        private fun triggerScreenLock() {
            val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, AuraAdminReceiver::class.java)

            if (devicePolicyManager.isAdminActive(adminComponent)) {
                devicePolicyManager.lockNow()
            } else {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Aura needs permission to lock the screen on double-tap.")
                }
                startActivity(intent)
            }
        }

        private fun fetchInstalledApplications(): List<Map<String, Any>> {
            val apps = mutableListOf<Map<String, Any>>()
            val pm = packageManager
            val mainIntent = Intent(Intent.ACTION_MAIN, null).apply { addCategory(Intent.CATEGORY_LAUNCHER) }
            val launchables = pm.queryIntentActivities(mainIntent, 0)

            for (resolveInfo in launchables) {
                val packageName = resolveInfo.activityInfo.packageName
                val name = resolveInfo.loadLabel(pm).toString()

                val drawable = resolveInfo.loadIcon(pm)
                val base64Icon = drawableToBase64(drawable)

                apps.add(mapOf(
                    "name" to name,
                    "package" to packageName,
                    "icon" to base64Icon
                ))
            }
            return apps.sortedBy { (it["name"] as String).lowercase(Locale.ROOT) }
        }

        private fun drawableToBase64(drawable: Drawable): String {
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 100
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 100
                val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }

            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            val byteArray = outputStream.toByteArray()
            return Base64.encodeToString(byteArray, Base64.NO_WRAP)
        }

        private fun executeLaunchIntent(pkgName: String): Boolean {
            return try {
                val pm: PackageManager = packageManager
                val launchIntent: Intent? = pm.getLaunchIntentForPackage(pkgName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(launchIntent)
                    true
                } else {
                    if (pkgName == "com.android.dialer") {
                        startActivity(Intent(Intent.ACTION_DIAL).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) })
                        return true
                    }
                    false
                }
            } catch (e: Exception) { false }
        }

        private fun isNotificationServiceEnabled(): Boolean {
            val pkgName = packageName
            val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
            if (flat != null && flat.isNotEmpty()) {
                val names = flat.split(":")
                for (name in names) {
                    val componentName = android.content.ComponentName.unflattenFromString(name)
                    if (componentName != null && componentName.packageName == pkgName) {
                        return true
                    }
                }
            }
            return false
        }

        override fun onBackPressed() {}
}
