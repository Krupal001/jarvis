import 'package:flutter_contacts/flutter_contacts.dart';

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