package com.example.flutter_gemma_demo

/**
 * Separate activity for assistant-mode launches.
 *
 * `windowIsTranslucent` must be present in the manifest theme *before* the
 * window is created — calling `setTheme()` in `onCreate()` is too late.
 * Declaring this activity with `TransparentAssistantTheme` is the only way
 * to get a translucent window reliably.
 *
 * Inherits all method channels from [MainActivity]; `isAssistantMode` is
 * computed as `this is AssistActivity`, so `getBackgroundMode()` returns
 * transparent automatically.
 */
class AssistActivity : MainActivity()
