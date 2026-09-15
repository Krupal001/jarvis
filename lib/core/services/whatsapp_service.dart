import 'package:flutter_gemma_demo/core/services/automation_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contact_service.dart';

class WhatsAppService {
  final ContactService contactService;

  WhatsAppService({
    required this.contactService,
  });

  Future<String> sendWhatsAppToContact({
    required String contactName,
    required String message,
  }) async {
    final phoneNumber =
        await contactService.findPhoneNumber(contactName);
    if (phoneNumber == null) {
      return 'Could not find a phone number for $contactName.';
    }

    await AutomationService.start('send-whatsapp');
    final opened = await sendWhatsApp(
      phoneNumber: phoneNumber,
      message: message,
    );

    if (!opened) { 
      await AutomationService.stop();
      return 'WhatsApp is not installed on this device. '
          'Resolved number for $contactName: $phoneNumber. '
          'Message: "$message"';
    }

    return 'WhatsApp chat opened for $contactName'
        'and $message was sent successfully.';
  }

  /// Opens WhatsApp's chat screen with the number and message pre-filled.
  ///
  /// Tries the `whatsapp://` app deep link first (opens the app directly). If
  /// WhatsApp isn't installed (no activity handles the scheme), falls back to
  /// the `https://wa.me/` web link (opens the browser → WhatsApp Web).
  ///
  /// Returns `false` if neither could be launched.
  Future<bool> sendWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    // WhatsApp requires the number in international format without +, spaces,
    // dashes or leading zeros. Strip everything that isn't a digit.
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If the number is 10 digits (no country code), prepend India's code (91).
    // If it starts with 0 (local trunk prefix), remove the 0 and prepend 91.
    if (cleanNumber.startsWith('0') && cleanNumber.length == 11) {
      cleanNumber = '91${cleanNumber.substring(1)}';
    } else if (cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }
    final encodedText = Uri.encodeComponent(message);

    // 1. Try the native app deep link first.
    // final appUri = Uri.parse(
    //   'whatsapp://send?phone=$cleanNumber&text=$encodedText',
    // );
    // if (await canLaunchUrl(appUri)) {
    //   return launchUrl(appUri, mode: LaunchMode.externalApplication);
    // }

    // 2. Fall back to the web link (works without the app installed).
    final webUri = Uri.parse(
      'https://wa.me/$cleanNumber?text=$encodedText',
    );
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
