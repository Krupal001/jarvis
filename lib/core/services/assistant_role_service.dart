import 'package:flutter/services.dart';

class AssistantRoleService {
  static const _channel = MethodChannel('assistant_control');

  Future<String?> requestAssistantRole() async {
    try {
      return await _channel.invokeMethod<String>('requestAssistantRole');
    } on PlatformException catch (e) {
      return 'error: ${e.message}';
    }
  }
  Future<bool> isAssistantRoleHeld() async {
    try {
      return await _channel.invokeMethod<bool>('isAssistantRoleHeld') ?? false;
    } on PlatformException {
      return false;
    }
  }
}