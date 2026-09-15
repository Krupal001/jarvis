import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_demo/core/services/automation_service.dart';
import 'package:flutter_gemma_demo/core/services/device_info_service.dart';
import 'package:flutter_gemma_demo/core/services/play_store_search_service.dart';
import 'package:flutter_gemma_demo/core/services/sms_service.dart';
import 'package:flutter_gemma_demo/core/services/uninstall_app_service.dart';
import 'package:flutter_gemma_demo/core/services/whatsapp_service.dart';
import 'package:flutter_gemma_demo/chat/chat_models.dart';
import 'package:url_launcher/url_launcher.dart';

class ToolHandler {
  ToolHandler({
    required this._smsService,
    required this._whatsappService,
    required this._playStoreService,
    required this._uninstallAppService,
    required this._deviceInfoService,
  });

  final SmsService _smsService;
  final WhatsAppService _whatsappService;
  final PlayStoreSearchService _playStoreService;
  final UninstallAppService _uninstallAppService;
  final DeviceInfoService _deviceInfoService;

  Future<Map<String, dynamic>> handle(
    FunctionCallResponse call, {
    required void Function(AgentStep step) onStep,
  }) async {
    onStep(AgentStep('${call.name}(${_formatArgs(call.args)})'));
    try {
      final result = await _dispatch(call);
      onStep(AgentStep('Done: $result'));
      return {'result': result, 'status': 'success'};
    } catch (e) {
      onStep(AgentStep('Error: $e', isError: true));
      return {'error': e.toString(), 'status': 'failed'};
    }
  }

  Future<String> _dispatch(FunctionCallResponse call) {
    switch (call.name) {
      case 'send_sms':
        return _smsService.sendSmsToContact(
          contactName: call.args['contactName'] as String,
          message: call.args['message'] as String,
        );
      case 'send_whatsapp':
        return _whatsappService.sendWhatsAppToContact(
          contactName: call.args['contactName'] as String,
          message: call.args['message'] as String,
        );
      case 'install_app':
        return _installApp(call.args['appName'] as String);
      case 'uninstall_app':
        return _uninstallAppService.uninstallApp(call.args['appName'] as String);
      case 'get_device_info':
        return _deviceInfoService.getInfo(call.args['field'] as String);
      default:
        return Future.value('Unknown tool: ${call.name}');
    }
  }

  Future<String> _installApp(String appName) async {
    final app = await _playStoreService.searchApp(appName);
    if (app == null) return 'Could not find "$appName" on Google Play Store.';
    await AutomationService.start('install-app');
    final launched = await launchUrl(
      Uri.parse(app.playStoreUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) return 'Could not open Play Store for ${app.title}.';
    return 'Opened Google Play Store for ${app.title}. Tap Install to proceed.';
  }

  static String _formatArgs(Map<String, dynamic> args) =>
      args.entries.map((e) => '${e.key}: ${e.value}').join(', ');
}
