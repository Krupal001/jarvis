import 'package:flutter_gemma_demo/core/services/automation_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contact_service.dart';

class SmsService {
  final ContactService contactService;

  SmsService({
    required this.contactService,
  });

  Future<String> sendSmsToContact({
    required String contactName,
    required String message,
  }) async {
    final phoneNumber =
        await contactService.findPhoneNumber(contactName);

    if (phoneNumber == null) {
      return 'Could not find a phone number for $contactName.';
    }
    await AutomationService.start('send-sms');
    await sendSms(
      phoneNumber: phoneNumber,
      message: message,
    );

    return 'SMS composer opened for $contactName ($phoneNumber). '
        'Press send to deliver the message.';
  }

  /// Opens the OS SMS composer with the number and message pre-filled.
  /// The user reviews and presses send — nothing is sent silently.
  Future<void> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      query: _encodeQuery({'body': message}),
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open SMS composer for $phoneNumber.');
    }
  }

  /// Percent-encodes a query map the same way the flutter_gemma_agent
  /// NativeIntentExecutor does (space → %20, etc.).
  static String _encodeQuery(Map<String, String> params) {
    return params.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
