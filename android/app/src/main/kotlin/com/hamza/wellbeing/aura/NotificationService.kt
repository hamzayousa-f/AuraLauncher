package com.hamza.wellbeing.aura

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.app.Notification

class NotificationService : NotificationListenerService() {

    companion object {
        private var instance: NotificationService? = null

            fun getActiveNotificationsCount(): Int {
                return instance?.activeNotifications?.size ?: 0
            }

            fun getActiveNotificationsData(): List<HashMap<String, String>> {
                val dataList = ArrayList<HashMap<String, String>>()
                val currentInstance = instance ?: return dataList

                try {
                    val activeNotifications = currentInstance.activeNotifications
                    if (activeNotifications != null) {
                        for (sbn in activeNotifications) {
                            val extras = sbn.notification?.extras
                            if (extras != null) {
                                val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
                                val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

                                if (title.isNotEmpty() || text.isNotEmpty()) {
                                    val map = HashMap<String, String>()
                                    map["packageName"] = sbn.packageName ?: ""
                                    map["title"] = title
                                    map["text"] = text
                                    dataList.add(map)
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    // Fail-safe graceful fallback for compilation or runtime security blocks
                }
                return dataList
            }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        instance = null
    }
}
