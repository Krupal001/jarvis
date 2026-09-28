//package com.example.flutter_gemma_demo
//
//import android.content.Context
//import android.content.Intent
//import android.os.Bundle
//import android.service.voice.VoiceInteractionSession
//
//class MyVoiceInteractionSession(context: Context) : VoiceInteractionSession(context) {
//
//    override fun onShow(args: Bundle?, showFlags: Int) {
//        super.onShow(args, showFlags)
//
//        val launchIntent = Intent(context, MainActivity::class.java).apply {
//            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
//                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
//                    Intent.FLAG_ACTIVITY_SINGLE_TOP
//            putExtra("launched_from_assistant", true)
//        }
//        startAssistantActivity(launchIntent)
//
//        // The session window itself shows nothing — your app takes over.
//        hide()
//    }
//}

package com.example.flutter_gemma_demo

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.voice.VoiceInteractionSession

class MyVoiceInteractionSession(
    context: Context
) : VoiceInteractionSession(context) {

    override fun onShow(args: Bundle?, showFlags: Int) {
        super.onShow(args, showFlags)

        // Prevent the default VoiceInteractionSession window
        // because Flutter will display the assistant UI.
        setUiEnabled(false)

        val launchIntent = Intent(context, AssistActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP

            putExtra("launched_from_assistant", true)
        }

        startAssistantActivity(launchIntent)
    }
}