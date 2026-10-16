import 'package:flutter_contacts/flutter_contacts.dart';

/// Returns true if [input] looks like a phone number rather than a name —
/// i.e. it contains only digits, spaces, and the characters `+ - ( )`.
bool isPhoneNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return false;
  return RegExp(r'^\+?[\d\s\-().]{5,}$').hasMatch(trimmed);
}

class ContactService {
  Future<String?> findPhoneNumber(String name) async {
    final contacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.name,
        ContactProperty.phone,
      },
    );

    final query = name.trim().toLowerCase();

    for (final contact in contacts) {
      if (contact.displayName?.toLowerCase().contains(query) == true) {
        if (contact.phones.isNotEmpty) {
          return contact.phones.first.number;
        }
      }
    }

    return null;
  }
}