package com.example.flutter_gemma_demo

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings

class MainActivity : FlutterActivity() {

    private val CHANNEL = "automation_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "startAutomation" -> {
                    val task = call.argument<String>("task")

                    AutomationState.activeTask = task

                    result.success(true)
                }

                "stopAutomation" -> {
                    AutomationState.activeTask = null

                    result.success(true)
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "checkAccessibilityEnabled" -> {
                    val accessibilityManager =
                        getSystemService(ACCESSIBILITY_SERVICE)
                                as android.view.accessibility.AccessibilityManager

                    val enabledServices =
                        accessibilityManager.getEnabledAccessibilityServiceList(
                            android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK
                        )

                    val enabled = enabledServices.any {
                        it.resolveInfo.serviceInfo.packageName == packageName &&
                                it.resolveInfo.serviceInfo.name ==
                                "com.example.flutter_gemma_demo.PlayStoreAccessibilityService"
                    }

                    result.success(enabled)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}