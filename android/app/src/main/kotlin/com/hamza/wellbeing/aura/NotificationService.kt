package com.hamza.wellbeing.aura

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationService : NotificationListenerService() {

    companion object {
        private var activeNotificationCount = 0

        fun getNotificationCount(): Int {
            return activeNotificationCount
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        updateCount()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        updateCount()
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        updateCount()
    }

    private fun updateCount() {
        val activeNotifications = try {
            activeNotifications
        } catch (e: Exception) {
            null
        }

        // Filter out ongoing system notifications (like media players or persistent status items)
        activeNotificationCount = activeNotifications?.filter { sbn ->
            val isOngoing = (sbn.notification.flags and android.app.Notification.FLAG_ONGOING_EVENT) != 0
            val isLocalOnly = (sbn.notification.flags and android.app.Notification.FLAG_LOCAL_ONLY) != 0
            !isOngoing && !isLocalOnly
        }?.size ?: 0
    }
}
