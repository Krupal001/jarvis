import 'package:flutter_gemma_agent/flutter_gemma_agent.dart';
import 'package:flutter_gemma_demo/core/services/uninstall_app_service.dart';

class UninstallAppExecutor implements SkillExecutor {
  final UninstallAppService _uninstallAppService;
  
  UninstallAppExecutor({
    required UninstallAppService uninstallAppService,
  }) : _uninstallAppService = uninstallAppService;
  
  @override
  String get name => 'uninstall-app';
  
  @override
  int get priority => 10;
  
  @override
  bool canExecute(String skillType) {
    return skillType == 'text';
  }
  
  @override
  bool canExecuteSkill(Skill skill) {
    return skill.name == 'uninstall-app';
  }
  
  @override
  Future<SkillResult> execute(
    Skill skill, 
    String dataJson, {
    String? secret,
  }) async {
    try {
      final result = await _uninstallAppService.uninstallApp(dataJson);

      if (!result.contains('not found')) {
        return ErrorResult(
          result,
        );
      }
      return TextResult(
        result,
      );
      
    } catch (e) {
      return ErrorResult(
        'Failed to uninstall app: $e',
      );
    }
  }
  
}
