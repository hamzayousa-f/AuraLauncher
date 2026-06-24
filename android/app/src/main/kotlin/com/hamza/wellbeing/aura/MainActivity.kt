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
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar
import java.util.Locale
import org.json.JSONArray

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hamza.wellbeing.aura/launcher"
    private var packageRemovedReceiver: BroadcastReceiver? = null

        override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
            super.configureFlutterEngine(flutterEngine)

            // Register system receiver to catch uninstalled packages in real-time
            registerUninstallReceiver()

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
                    // Handle BOTH method names to satisfy both the UI components and the UsageService
                    "getAppUsageStats", "getNativeScreenTime" -> {
                        // Use arguments if provided by the service; otherwise fall back to today's midnight
                        val startTime = call.argument<Long>("startTime") ?: Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }.timeInMillis

                        val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()

                        result.success(getDeviceScreenTimeMinutes(startTime, endTime))
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
                    else -> result.notImplemented()
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

                            // Clean up SharedPreferences data sync layers instantly
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
                // Handle parsing file boundaries safely
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

        private fun getDeviceScreenTimeMinutes(startTime: Long, endTime: Long): Map<String, Int> {
            val statsMap = mutableMapOf<String, Int>()
            if (!isUsageStatsPermissionGranted()) return statsMap

                val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

                // Calculate strict local midnight
                val calendar = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val midnightToday = calendar.timeInMillis
                val now = System.currentTimeMillis()

                // queryAndAggregateUsageStats returns a combined Map<String, UsageStats>
                // strictly for the time window provided, bypassing individual interval bucket glitches.
                val aggregatedStats = usageStatsManager.queryAndAggregateUsageStats(midnightToday, now)

                if (aggregatedStats != null && aggregatedStats.isNotEmpty()) {
                    for ((packageName, stat) in aggregatedStats) {
                        if (stat.totalTimeInForeground > 0) {
                            // Double check that the app was actually touched today
                            if (stat.lastTimeUsed >= midnightToday || stat.lastTimeStamp >= midnightToday) {
                                val minutes = (stat.totalTimeInForeground / (1000 * 60)).toInt()
                                if (minutes > 0) {
                                    statsMap[packageName] = minutes
                                }
                            }
                        }
                    }
                }
                return statsMap
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

        override fun onBackPressed() {}
}
