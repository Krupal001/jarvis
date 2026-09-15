import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A static light gradient background (no animation).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            AppColors.bgBase,
            Color(0xFFE0E7FF),
          ],
        ),
      ),
    );
  }
}
