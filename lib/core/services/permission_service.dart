import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

class PermissionService {
  static Future<bool> isAccessibilityPermissionEnabled() async {
    return await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
  }

  static Future<bool> requestAccessibilityPermission() async {
    return await FlutterAccessibilityService.requestAccessibilityPermission();
  }
}