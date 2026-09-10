import 'dart:convert';

import 'package:flutter_gemma_agent/flutter_gemma_agent.dart';
import 'package:flutter_gemma_demo/core/services/uninstall_app_service.dart';

class UninstallAppExecutor implements SkillExecutor {
  final UninstallAppService _uninstallAppService;
  
  UninstallAppExecutor({
    required UninstallAppService uninstallAppService,
  }) : _uninstallAppService = uninstallAppService;
  
  @override
  String get name => 'uninstall-app';
  
  @override
  int get priority => 10;
  
  @override
  bool canExecute(String skillType) {
    return skillType == 'text';
  }
  
  @override
  bool canExecuteSkill(Skill skill) {
    return skill.name == 'uninstall-app';
  }
  
  @override
  Future<SkillResult> execute(
    Skill skill, 
    String dataJson, {
    String? secret,
  }) async {
    try {
      final appName = _extractAppName(dataJson);

      if (appName == null || appName.trim().isEmpty) {
        return ErrorResult(
          'Could not determine the application name.',
        );
      }

      final result = await _uninstallAppService.uninstallApp(appName.trim());

      if (!result.contains('not found')) {
        return ErrorResult(
          result,
        );
      }
      return TextResult(
        result,
      );
      
    } catch (e) {
      return ErrorResult(
        'Failed to uninstall app: $e',
      );
    }
  }

  String? _extractAppName(String dataJson) {
    final value = dataJson.trim();

    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('{') && value.endsWith('}')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          for (final v in decoded.values) {
            if (v is String && v.trim().isNotEmpty) {
              return v.trim();
            }
          }
        }
      } catch (_) {}

      final inner = value.substring(1, value.length - 1).trim();
      final colonIdx = inner.indexOf(':');
      if (colonIdx != -1) {
        final val = inner.substring(colonIdx + 1).trim();
        final cleaned = val.replaceAll(RegExp('^["\']|["\']\$'), '');
        if (cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    }

    if (value.startsWith('[') && value.endsWith(']')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
        }
      } catch (_) {}
    }

    return value;
  }
}
