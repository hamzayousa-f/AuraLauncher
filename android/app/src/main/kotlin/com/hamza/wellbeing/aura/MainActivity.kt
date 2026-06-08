package com.hamza.wellbeing.aura

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hamza.wellbeing.aura/launcher"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                "getNativeScreenTime" -> {
                    result.success(getDeviceScreenTimeMinutes())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
                                         packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getDeviceScreenTimeMinutes(): Map<String, Int> {
        val statsMap = mutableMapOf<String, Int>()
        if (!isUsageStatsPermissionGranted()) return statsMap

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

            // Calculate the timeframe beginning from midnight today
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            // Query daily interval metrics
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, startTime, endTime
            )

            if (usageStats != null) {
                for (stat in usageStats) {
                    val totalTimeInForeground = stat.totalTimeInForeground
                    if (totalTimeInForeground > 0) {
                        val minutes = (totalTimeInForeground / (1000 * 60)).toInt()
                        // Aggregate times if duplicate packages appear in system logs
                        statsMap[stat.packageName] = (statsMap[stat.packageName] ?: 0) + minutes
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
            apps.add(mapOf(
                "name" to resolveInfo.loadLabel(pm).toString(),
                           "package" to resolveInfo.activityInfo.packageName
            ))
        }
        return apps.sortedBy { (it["name"] as String).lowercase(Locale.ROOT) }
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
