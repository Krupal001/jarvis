import 'package:flutter/material.dart';
import 'package:flutter_gemma_demo/ui/app_theme.dart';
import 'package:lottie/lottie.dart';

class WelcomeState extends StatefulWidget {
  const WelcomeState({super.key});

  @override
  State<WelcomeState> createState() => _WelcomeStateState();
}

class _WelcomeStateState extends State<WelcomeState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typeController;
  static const _fullText = 'How may I help you?';

  @override
  void initState() {
    super.initState();
    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/Ghostsmart.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _typeController,
            builder: (context, _) {
              final charCount =
                  (_typeController.value * _fullText.length).floor();
              final shown =
                  _fullText.substring(0, charCount.clamp(0, _fullText.length));
              final showCursor = _typeController.value < 1.0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shown,
                    style: AppText.heading.copyWith(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showCursor)
                    Text(
                      '|',
                      style: AppText.heading.copyWith(
                        fontSize: 24,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
