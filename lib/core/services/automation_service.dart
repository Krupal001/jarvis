import 'package:flutter/services.dart';

class AutomationService {
  static const MethodChannel _channel =
      MethodChannel('automation_control');

  static Future<void> start(String task) async {
    await _channel.invokeMethod(
      'startAutomation',
      {'task': task},
    );
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stopAutomation');
  }


  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

static Future<bool> isAccessibilityEnabled() async {
    return await _channel.invokeMethod<bool>(
          'checkAccessibilityEnabled',
        ) ??
        false;
  }

}