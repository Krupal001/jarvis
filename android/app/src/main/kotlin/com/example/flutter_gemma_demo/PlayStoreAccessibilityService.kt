package com.example.flutter_gemma_demo

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log

class PlayStoreAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "PlayStoreAccessibility"

        var instance: PlayStoreAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this

        Log.d(TAG, "Accessibility service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val task = AutomationState.activeTask ?: return
        //val task = AutomationState.activeTask
        val packageName = event.packageName?.toString()

        Log.d(
            TAG,
            "Event: package=$packageName task=$task"
        )

        when (task) {

            "install-app" -> {
                if (packageName == "com.android.vending") {
                    findAndClickInstallButton()
                }
            }

            "send-whatsapp" -> {
                if (packageName == "com.whatsapp") {
                    findAndClickWhatsAppSendButton()
                }
            }
            "send-sms" -> {
                if (packageName == "com.google.android.apps.messaging") {
                    findAndClickSmsSendButton()
                }
            }
        }
    }

    private fun findAndClickSmsSendButton() {
        val root = rootInActiveWindow ?: return

        val sendNode = findSmsSendNode(root)

        if (sendNode == null) {
            Log.d(TAG, "SMS Send button not found")
            return
        }

        Log.d(TAG, "SMS Send button FOUND")

        val result = sendNode.performAction(
            AccessibilityNodeInfo.ACTION_CLICK
        )

        Log.d(TAG, "SMS SEND CLICK RESULT = $result")

        if (result) {
            AutomationState.activeTask = null
        }
    }


//    private fun findAndClickSmsSendButton() {
//        val root = rootInActiveWindow ?: return
//
//        Log.d(TAG, "========== SEARCHING SMS SEND ==========")
//
//        findSmsSendNodes(root)
//
//        Log.d(TAG, "========================================")
//    }

    private fun findSmsSendNodes(node: AccessibilityNodeInfo) {

        val text = node.text?.toString()
        val desc = node.contentDescription?.toString()
        val id = node.viewIdResourceName
        val className = node.className?.toString()

        if (
            text?.contains("send", ignoreCase = true) == true ||
            desc?.contains("send", ignoreCase = true) == true ||
            id?.contains("send", ignoreCase = true) == true
        ) {
            Log.d(TAG, "===== SEND RELATED NODE =====")
            Log.d(TAG, "class=$className")
            Log.d(TAG, "text=$text")
            Log.d(TAG, "desc=$desc")
            Log.d(TAG, "id=$id")
            Log.d(TAG, "clickable=${node.isClickable}")
            Log.d(TAG, "enabled=${node.isEnabled}")
            Log.d(TAG, "visible=${node.isVisibleToUser}")
            Log.d(TAG, "focusable=${node.isFocusable}")
            Log.d(TAG, "actions=${node.actionList}")
            Log.d(TAG, "parent=${node.parent?.className}")
            Log.d(TAG, "============================")
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            findSmsSendNodes(child)
        }
    }

    private fun findSmsSendNode(
        node: AccessibilityNodeInfo
    ): AccessibilityNodeInfo? {

        if (
            node.isVisibleToUser &&
            node.isEnabled &&
            node.isClickable &&
            node.viewIdResourceName == "Compose:Draft:Send"
        ) {
            return node
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue

            val result = findSmsSendNode(child)

            if (result != null) {
                return result
            }
        }

        return null
    }

//    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
//        if (event == null) return
//
//        val packageName = event.packageName?.toString()
//        val task = AutomationState.activeTask
//
//        Log.d(
//            TAG,
//            "========================================"
//        )
//        Log.d(
//            TAG,
//            "EVENT: package=$packageName"
//        )
//        Log.d(
//            TAG,
//            "EVENT TYPE: ${event.eventType}"
//        )
//        Log.d(
//            TAG,
//            "ACTIVE TASK: $task"
//        )
//
//        val root = rootInActiveWindow
//
//        if (root == null) {
//            Log.d(TAG, "ROOT: null")
//            return
//        }
//
//        Log.d(TAG, "========== ACCESSIBILITY TREE ==========")
//
//        logAccessibilityTree(root)
//        findSmsSendNodes(root)
//
//
//        Log.d(TAG, "========================================")
//    }

    private fun findAndClickWhatsAppSendButton() {
        val root = rootInActiveWindow ?: return

        val sendButton = findWhatsAppSendButton(root)

        if (sendButton == null) {
            Log.d(TAG, "WhatsApp Send button not found")
            return
        }

        Log.d(TAG, "WhatsApp Send button FOUND")

        val result = sendButton.performAction(
            AccessibilityNodeInfo.ACTION_CLICK
        )

        Log.d(TAG, "WHATSAPP SEND CLICK RESULT = $result")

        if (result) {
            AutomationState.activeTask = null
        }
    }


    private fun findWhatsAppSendButton(
        node: AccessibilityNodeInfo
    ): AccessibilityNodeInfo? {

        if (
            node.isVisibleToUser &&
            node.isEnabled &&
            node.isClickable &&
            node.viewIdResourceName == "com.whatsapp:id/send"
        ) {
            return node
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue

            val result = findWhatsAppSendButton(child)

            if (result != null) {
                return result
            }
        }

        return null
    }

    private fun logAccessibilityTree(
        node: AccessibilityNodeInfo,
        depth: Int = 0
    ) {
        val indent = "  ".repeat(depth)

        Log.d(
            TAG,
            "$indent class=${node.className} " +
                    "text=${node.text} " +
                    "desc=${node.contentDescription} " +
                    "clickable=${node.isClickable} " +
                    "enabled=${node.isEnabled} " +
                    "visible=${node.isVisibleToUser} " +
                    "id=${node.viewIdResourceName}"
        )

        for (i in 0 until node.childCount) {
            node.getChild(i)?.let {
                logAccessibilityTree(it, depth + 1)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
    }

    private fun findAndClickInstallButton() {
        val root = rootInActiveWindow ?: return

        val installContainer = findInstallNode(root)

        if (installContainer == null) {
            Log.d(TAG, "Install container not found")
            return
        }

        Log.d(TAG, "Install container FOUND")

        var current: AccessibilityNodeInfo? = installContainer

        while (current != null) {

            Log.d(
                TAG,
                "Checking node: " +
                        "class=${current.className}, " +
                        "text=${current.text}, " +
                        "desc=${current.contentDescription}, " +
                        "clickable=${current.isClickable}"
            )

            if (
                current.isVisibleToUser &&
                current.isEnabled &&
                current.isClickable
            ) {
                val result = current.performAction(
                    AccessibilityNodeInfo.ACTION_CLICK
                )

                Log.d(
                    TAG,
                    "INSTALL CLICK RESULT = $result"
                )

                if (result) {
                    AutomationState.activeTask = null
                    return
                }
            }

            current = current.parent
        }

        Log.d(TAG, "Could not click Install container")
    }
    private fun findInstallNode(
        node: AccessibilityNodeInfo
    ): AccessibilityNodeInfo? {

        val description = node.contentDescription?.toString()
        val text = node.text?.toString()

        if (
            node.isVisibleToUser &&
            (
                    description.equals("Install", ignoreCase = true) ||
                            text.equals("Install", ignoreCase = true)
                    )
        ) {
            Log.d(
                TAG,
                "FOUND INSTALL NODE: " +
                        "class=${node.className}, " +
                        "text=$text, " +
                        "desc=$description, " +
                        "clickable=${node.isClickable}"
            )

            return node
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue

            val result = findInstallNode(child)

            if (result != null) {
                return result
            }
        }

        return null
    }
}