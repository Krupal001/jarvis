import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma_agent/flutter_gemma_agent.dart';
import 'package:flutter_gemma_demo/core/services/sms_service.dart';
import 'package:flutter_gemma_demo/core/services/whatsapp_service.dart';

/// Handles messaging native intents (`send_sms`, `send_whatsapp`).
///
/// One executor handles BOTH intents because the [SkillExecutor] contract
/// requires [canExecuteSkill] to select on [SkillType] alone — two separate
/// executors both returning `true` for `SkillType.intent` would race, and
/// only the first-registered one would ever win. The concrete intent name is
/// dispatched inside [execute], where the full skill is available.
///
/// This mirrors how the package's own [NativeIntentExecutor] handles all
/// whitelisted intents (send_email, send_text, create_calendar_event, ...)
/// from a single executor.
class MessagingSkillExecutor extends SkillExecutor {
  final SmsService smsService;
  final WhatsAppService whatsappService;

  MessagingSkillExecutor({
    required this.smsService,
    required this.whatsappService,
  });

  @override
  String get name => 'MessagingSkillExecutor';

  @override
  int get priority => 10;

  @override
  bool canExecuteSkill(Skill skill) =>
      skill.name == 'send-sms' ||
      skill.name == 'send-whatsapp' ||
      skill.type == SkillType.intent;

  @override
  Future<SkillResult> execute(
    Skill skill,
    String dataJson, {
    String? secret,
  }) async {
    // The agent loop sets the synthetic skill's name to the intent value the
    // model passed to `runIntent(intent, parameters)`.
    switch (skill.name) {
      case 'send-sms':
        return _sendSms(dataJson);
      case 'send-whatsapp':
        return _sendWhatsApp(dataJson);
      default:
        return ErrorResult(
          'MessagingSkillExecutor does not handle "${skill.name}". '
          'Supported intents: send_sms, send_whatsapp.',
        );
    }
  }

  Future<SkillResult> _sendSms(String dataJson) async {
    try {
      final data = _decode(dataJson);
      final contactName = data['contactName'] as String?;
      final message = data['message'] as String?;

      if (contactName == null || contactName.trim().isEmpty) {
        return ErrorResult('Contact name is required.');
      }
      if (message == null || message.trim().isEmpty) {
        return ErrorResult('Message is required.');
      }

      final result = await smsService.sendSmsToContact(
        contactName: contactName,
        message: message,
      );
      return TextResult(result);
    } catch (e) {
      return ErrorResult('Failed to send SMS: $e');
    }
  }

  Future<SkillResult> _sendWhatsApp(String dataJson) async {
    try {
      final data = _decode(dataJson);
      final contactName = data['contactName'] as String?;
      final message = data['message'] as String?;

      if (contactName == null || contactName.trim().isEmpty) {
        return ErrorResult('Contact name is required.');
      }
      if (message == null || message.trim().isEmpty) {
        return ErrorResult('Message is required.');
      }

      final result = await whatsappService.sendWhatsAppToContact(
        contactName: contactName,
        message: message,
      );
      return TextResult(result);
    } catch (e) {
      return ErrorResult('Failed to send WhatsApp message: $e');
    }
  }

  Map<String, dynamic> _decode(String json) {
    final value = json.trim();
    if (value.isEmpty) return {};

    debugPrint('[MessagingSkillExecutor] raw dataJson: "$value"');

    // Try parsing as JSON first.
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      // Not valid JSON — try manual extraction below.
    }

    // Try non-standard JSON like {contactName: Samir, message: hello}
    // or without braces: contactName: Samir, message: hello
    final hasBraces = value.startsWith('{') && value.endsWith('}');
    final inner = hasBraces ? value.substring(1, value.length - 1) : value;

    // Check if this looks like key:value pairs (has a colon before any comma)
    final firstColon = inner.indexOf(':');
    final firstComma = inner.indexOf(',');
    if (firstColon > 0 && (firstComma == -1 || firstColon < firstComma)) {
      final result = <String, dynamic>{};
      final parts = _splitArgs(inner);
      var allParsed = true;
      for (final part in parts) {
        final colonIdx = part.indexOf(':');
        if (colonIdx != -1) {
          final key = part.substring(0, colonIdx).trim();
          var val = part.substring(colonIdx + 1).trim();
          val = val.replaceAll(RegExp('^["\']|["\']\$'), '');
          if (key.isNotEmpty && val.isNotEmpty) {
            result[key] = val;
          } else {
            allParsed = false;
          }
        } else {
          allParsed = false;
        }
      }
      if (allParsed && result.isNotEmpty) return result;
    }

    // Plain text fallback: try to split into name and message.
    // Patterns: "Samir, hello", "Samir: hello"
    // But only if the part before the separator looks like a name (not a key name).
    for (final sep in [',', ':']) {
      final idx = value.indexOf(sep);
      if (idx > 0) {
        final name = value.substring(0, idx).trim();
        final msg = value.substring(idx + 1).trim();
        // Skip if the "name" looks like a key name (contactName, message, etc.)
        final lowerName = name.toLowerCase();
        if (lowerName == 'contactname' || lowerName == 'message' ||
            lowerName == 'contact' || lowerName == 'name') {
          continue;
        }
        if (name.isNotEmpty && msg.isNotEmpty) {
          return {'contactName': name, 'message': msg};
        }
      }
    }

    // Last resort: return as contactName (model may have sent just the name).
    return {'contactName': value};
  }

  List<String> _splitArgs(String input) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == '"' || ch == "'") {
        inQuotes = !inQuotes;
        current.write(ch);
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    if (current.isNotEmpty) result.add(current.toString());
    return result;
  }
}
