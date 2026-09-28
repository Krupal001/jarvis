package com.example.flutter_gemma_demo

import android.app.role.RoleManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivityLaunchConfigs

open class MainActivity : FlutterActivity() {

    private val CHANNEL = "automation_control"
    private val ASSISTANT_CHANNEL = "assistant_control"

    // AssistActivity is always assistant mode; MainActivity needs the intent extra.
    private val isAssistantMode: Boolean
        get() = this is AssistActivity ||
                intent?.getBooleanExtra("launched_from_assistant", false) == true

    private val INTENT_CHANNEL = "com.example.assistant/intent"
    private var intentChannel: MethodChannel? = null
    private val REQUEST_CODE_ROLE = 4242

//    private fun handleLaunchIntent(newIntent: Intent?) {
//        android.util.Log.d(
//            "AssistantIntent",
//            "Assistant mode: $isAssistantMode"
//        )
//    }
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//    }

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return if (isAssistantMode) {
            FlutterActivityLaunchConfigs.BackgroundMode.transparent
        } else {
            FlutterActivityLaunchConfigs.BackgroundMode.opaque
        }
    }

    override fun onNewIntent(newIntent: Intent) {
        super.onNewIntent(newIntent)

        setIntent(newIntent)

        //handleLaunchIntent(newIntent)

        // Notify Flutter when the Activity is reused.
        intentChannel?.invokeMethod(
            "assistantModeChanged",
            isAssistantMode
        )
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        intentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INTENT_CHANNEL
        )

        intentChannel?.setMethodCallHandler { call, result ->

            when (call.method) {

                "getLaunchIntentAction" -> {
                    result.success(
                        if (isAssistantMode) "ASSIST" else "DEFAULT"
                    )
                }

                else -> result.notImplemented()
            }
        }
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

        // --- Digital assistant role channel ---
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ASSISTANT_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAssistantRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(RoleManager::class.java)
                        when {
                            roleManager == null || !roleManager.isRoleAvailable(RoleManager.ROLE_ASSISTANT) ->
                                result.error(
                                    "UNAVAILABLE",
                                    "Assistant role not available on this device",
                                    null
                                )

                            roleManager.isRoleHeld(RoleManager.ROLE_ASSISTANT) ->
                                result.success("already_held")

                            else -> {
                                val intent =
                                    roleManager.createRequestRoleIntent(RoleManager.ROLE_ASSISTANT)
                                startActivityForResult(intent, REQUEST_CODE_ROLE)
                                result.success("requested")
                            }
                        }
                    } else {
                        result.error("UNSUPPORTED", "Requires Android 10 (API 29) or higher", null)
                    }
                }

                "isAssistantRoleHeld" -> {
                    val held = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        getSystemService(RoleManager::class.java)?.isRoleHeld(RoleManager.ROLE_ASSISTANT)
                            ?: false
                    } else false
                    result.success(held)
                }

                else -> result.notImplemented()
            }
        }
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        // requestCode == REQUEST_CODE_ROLE; resultCode == RESULT_OK means the
        // user picked this app as the assistant in the system dialog.
    }
}