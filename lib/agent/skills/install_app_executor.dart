import 'dart:convert';

import 'package:flutter_gemma_agent/flutter_gemma_agent.dart';
import 'package:flutter_gemma_demo/core/services/automation_service.dart';
import 'package:flutter_gemma_demo/core/services/play_store_search_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InstallAppExecutor implements SkillExecutor {
  final PlayStoreSearchService _playStoreSearchService;

  InstallAppExecutor({
    required PlayStoreSearchService playStoreSearchService,
  }) : _playStoreSearchService = playStoreSearchService;

  @override
  String get name => 'install-app';

  @override
  int get priority => 10;

  // Required by SkillExecutorProvider
  @override
  bool canExecute(String skillType) {
    return skillType == 'text';
  }

  @override
  bool canExecuteSkill(Skill skill) {
    return skill.name == 'install-app' &&
        skill.type == SkillType.textOnly;
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

      final app = await _playStoreSearchService.searchApp(
        appName.trim(),
      );

      if (app == null) {
        return ErrorResult(
          'Could not find "$appName" on Google Play Store.',
        );
      }

      await AutomationService.start('install-app');

      final launched = await launchUrl(
        Uri.parse(app.playStoreUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        return ErrorResult(
          'Could not open Google Play Store for ${app.title}.',
        );
      }

      return TextResult(
        'Opened Google Play Store for ${app.title}. '
        'Installation has been started.',
      );
    } catch (e) {
      return ErrorResult(
        'Failed to install app: $e',
      );
    }
  }

  String? _extractAppName(String dataJson) {
    final value = dataJson.trim();

    if (value.isEmpty) {
      return null;
    }

    // If the model passed a JSON object like {app_name: spotify} or
    // {"app_name": "spotify"}, extract the value.
    if (value.startsWith('{') && value.endsWith('}')) {
      // Try parsing as JSON first.
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          for (final v in decoded.values) {
            if (v is String && v.trim().isNotEmpty) {
              return v.trim();
            }
          }
        }
      } catch (_) {
        // Not valid JSON — try manual extraction.
      }
      // Manual extraction for non-standard JSON like {app_name: spotify}
      final inner = value.substring(1, value.length - 1).trim();
      final colonIdx = inner.indexOf(':');
      if (colonIdx != -1) {
        final val = inner.substring(colonIdx + 1).trim();
        // Remove surrounding quotes if present.
        final cleaned = val.replaceAll(RegExp('^["\']|["\']\$'), '');
        if (cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    }

    // If the model passed a JSON array like ["spotify"], extract the value.
    if (value.startsWith('[') && value.endsWith(']')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
        }
      } catch (_) {
        // Not valid JSON — return as-is.
      }
    }

    // Plain text — return as-is.
    return value;
  }
}