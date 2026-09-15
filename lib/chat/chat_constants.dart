import 'package:flutter_gemma/flutter_gemma.dart';

const chatSystemInstruction =
    'You are a helpful AI assistant for Android devices. '
    'You can send SMS, send WhatsApp messages, install or uninstall apps, '
    'and retrieve device information using the provided tools. '
    'Always ask for any missing required information before calling a tool. '
    'Be concise and friendly.';

const List<Tool> chatTools = [
  Tool(
    name: 'send_sms',
    description: 'Send an SMS message to a contact by name.',
    parameters: {
      'type': 'object',
      'properties': {
        'contactName': {
          'type': 'string',
          'description': 'Full name of the contact to send the SMS to.',
        },
        'message': {
          'type': 'string',
          'description': 'The text message content to send.',
        },
      },
      'required': ['contactName', 'message'],
    },
  ),
  Tool(
    name: 'send_whatsapp',
    description: 'Send a WhatsApp message to a contact by name.',
    parameters: {
      'type': 'object',
      'properties': {
        'contactName': {
          'type': 'string',
          'description': 'Full name of the contact to send the WhatsApp message to.',
        },
        'message': {
          'type': 'string',
          'description': 'The WhatsApp message content to send.',
        },
      },
      'required': ['contactName', 'message'],
    },
  ),
  Tool(
    name: 'install_app',
    description: 'Search and open the Google Play Store listing to install an Android app.',
    parameters: {
      'type': 'object',
      'properties': {
        'appName': {
          'type': 'string',
          'description': 'Name of the app to install.',
        },
      },
      'required': ['appName'],
    },
  ),
  Tool(
    name: 'uninstall_app',
    description: 'Uninstall an installed app from the device.',
    parameters: {
      'type': 'object',
      'properties': {
        'appName': {
          'type': 'string',
          'description': 'Name of the app to uninstall.',
        },
      },
      'required': ['appName'],
    },
  ),
  Tool(
    name: 'get_device_info',
    description: 'Get information about the device hardware or software.',
    parameters: {
      'type': 'object',
      'properties': {
        'field': {
          'type': 'string',
          'description':
              'The device info to retrieve. One of: model, manufacturer, brand, '
              'os, os_version, build_number, kernel, processor, memory, storage, '
              'display, battery, sensors, network, all.',
        },
      },
      'required': ['field'],
    },
  ),
];
