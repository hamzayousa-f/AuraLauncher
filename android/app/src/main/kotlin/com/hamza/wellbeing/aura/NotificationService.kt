package com.hamza.wellbeing.aura

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.app.Notification

class NotificationService : NotificationListenerService() {

    companion object {
        private var instance: NotificationService? = null

            fun getActiveNotificationsData(): List<Map<String, String>> {
                val dataList = mutableListOf<Map<String, String>>()
                instance?.activeNotifications?.forEach { sbn ->
                    val extras = sbn.notification.extras
                    val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
                    val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

                    if (title.isNotEmpty() || text.isNotEmpty()) {
                        val map = mapOf(
                            "packageName" to sbn.packageName,
                            "title" to title,
                            "text" to text
                        )
                        dataList.add(map)
                    }
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
