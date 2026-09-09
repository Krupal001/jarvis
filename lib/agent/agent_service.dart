import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_agent/flutter_gemma_agent.dart';
import 'package:flutter_gemma_demo/core/services/play_store_search_service.dart';
import 'package:flutter_gemma_demo/core/services/sms_service.dart';
import 'package:flutter_gemma_demo/core/services/whatsapp_service.dart';

import 'skills/messaging_skill_executor.dart';
import 'skills/install_app_executor.dart';

class AgentService {
  final SmsService smsService;
  final WhatsAppService whatsappService;

  AgentService({
    required this.smsService,
    required this.whatsappService,
  });

  static const _skillAssets = [
    'assets/skills/send-sms/SKILL.md',
    'assets/skills/send-whatsapp/SKILL.md',
    'assets/skills/install-app/SKILL.md',
  ];

  Future<AgentSession> createSession(InferenceModel model) async {
    final skills = <Skill>[];

    for (final path in _skillAssets) {
      final content = await rootBundle.loadString(path);
      skills.add(parseSkillMd(content));
    }

    final registry = SkillRegistry()
      ..addAll(
        skills,
        selected: true,
      );

    final messagingExecutor = MessagingSkillExecutor(
      smsService: smsService,
      whatsappService: whatsappService,
    );

    final installAppExecutor = InstallAppExecutor(
      playStoreSearchService: PlayStoreSearchService(),
    );

    return AgentSession.fromModel(
      model,
      registry: registry,
      executors: [
        messagingExecutor,
        installAppExecutor,
      ],
    );
  }
}