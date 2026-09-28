package com.example.flutter_gemma_demo

import android.speech.RecognitionService
import android.speech.SpeechRecognizer

class MyRecognitionService : RecognitionService() {
    override fun onStartListening(recognizerIntent: android.content.Intent?, listener: Callback?) {
        // Handle microphone stream / voice input trigger here
    }

    override fun onCancel(listener: Callback?) {
        // Stop listening
    }

    override fun onStopListening(listener: Callback?) {
        // Process audio
    }
}
