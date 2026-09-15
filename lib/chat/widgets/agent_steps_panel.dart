import 'package:flutter/material.dart';
import 'package:flutter_gemma_demo/chat/chat_models.dart';
import 'package:flutter_gemma_demo/ui/app_theme.dart';

class AgentStepsPanel extends StatelessWidget {
  const AgentStepsPanel({super.key, required this.steps});

  final List<AgentStep> steps;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
      leading: const Icon(Icons.psychology, size: 18, color: AppColors.primary),
      title: Text(
        'Tool Calls',
        style: AppText.bodySemiBold.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in steps)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.isError ? AppColors.red : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.text,
                          style: AppText.body.copyWith(
                            fontSize: 13,
                            color: s.isError
                                ? AppColors.red
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
