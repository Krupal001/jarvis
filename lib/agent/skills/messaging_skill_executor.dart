import 'dart:convert';

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
  bool canExecuteSkill(Skill skill) => skill.type == SkillType.intent;

  @override
  Future<SkillResult> execute(
    Skill skill,
    String dataJson, {
    String? secret,
  }) async {
    // The agent loop sets the synthetic skill's name to the intent value the
    // model passed to `runIntent(intent, parameters)`.
    switch (skill.name) {
      case 'send_sms':
        return _sendSms(dataJson);
      case 'send_whatsapp':
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
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) return decoded;
    throw FormatException('Expected a JSON object, got: $json');
  }
}
