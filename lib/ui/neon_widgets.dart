import 'dart:math';

import 'package:flutter/material.dart';

import 'neon_theme.dart';

/// A glassmorphic container with a subtle neon border glow.
class NeonGlassCard extends StatelessWidget {
  const NeonGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.glowColor = NeonColors.purple,
    this.glowBlur = 12,
    this.opacity = 0.06,
    this.borderOpacity = 0.2,
  });

  final Widget child;
  final double borderRadius;
  final Color glowColor;
  final double glowBlur;
  final double opacity;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withValues(alpha: opacity),
        border: Border.all(
          color: glowColor.withValues(alpha: borderOpacity),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.08),
            blurRadius: glowBlur,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A neon-gradient glowing button with press animation.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = NeonColors.primaryGradient,
    this.height = 52,
    this.borderRadius = 16,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Gradient gradient;
  final double height;
  final double borderRadius;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: NeonGlow.multi(blur: 8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: widget.onPressed,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: NeonText.bodyBold.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text with a neon glow effect (uses [Shadow] layers).
class NeonGlowText extends StatelessWidget {
  const NeonGlowText(
    this.text, {
    super.key,
    required this.style,
    this.glowColor,
    this.glowRadius = 12,
  });

  final String text;
  final TextStyle style;
  final Color? glowColor;
  final double glowRadius;

  @override
  Widget build(BuildContext context) {
    final color = glowColor ?? style.color ?? NeonColors.cyan;
    return Text(
      text,
      style: style.copyWith(
        shadows: [
          Shadow(color: color.withValues(alpha: 0.4), blurRadius: glowRadius),
        ],
      ),
    );
  }
}

/// A neon circular progress ring with a glowing arc.
class NeonProgressRing extends StatelessWidget {
  const NeonProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 6,
  });

  final double progress; // 0..1
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 0,
              color: NeonColors.purple.withValues(alpha: 0.15),
              strokeWidth: strokeWidth,
            ),
          ),
          // Progress arc
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              color: NeonColors.cyan,
              strokeWidth: strokeWidth,
              glow: true,
            ),
          ),
          // Percentage text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: NeonText.headingBold.copyWith(
                  fontSize: 22,
                  color: NeonColors.cyan,
                  shadows: NeonGlow.cyan(blur: 4)
                      .map((e) => Shadow(
                            color: e.color,
                            blurRadius: e.blurRadius,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.glow = false,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (glow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );

    // Inner glow arc (crisp)
    if (glow) {
      final crispPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        crispPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

/// Animated neon pulse ring — used for "thinking" / loading states.
class NeonPulseRing extends StatefulWidget {
  const NeonPulseRing({
    super.key,
    this.color = NeonColors.cyan,
    this.size = 80,
  });

  final Color color;
  final double size;

  @override
  State<NeonPulseRing> createState() => _NeonPulseRingState();
}

class _NeonPulseRingState extends State<NeonPulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PulsePainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final radius = t * size.width / 2;
      final alpha = (1 - t) * 0.25;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }

    // Core dot
    final corePaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, 5, corePaint);
    canvas.drawCircle(center, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => old.progress != progress;
}

/// A shimmering neon text that cycles through gradient colours.
class NeonShimmerText extends StatefulWidget {
  const NeonShimmerText(
    this.text, {
    super.key,
    this.style,
    this.colors = const [NeonColors.cyan, NeonColors.pink, NeonColors.purple],
    this.duration = const Duration(seconds: 3),
  });

  final String text;
  final TextStyle? style;
  final List<Color> colors;
  final Duration duration;

  @override
  State<NeonShimmerText> createState() => _NeonShimmerTextState();
}

class _NeonShimmerTextState extends State<NeonShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final c1 = Color.lerp(widget.colors[0], widget.colors[1], t)!;
        final c2 = Color.lerp(widget.colors[1], widget.colors[2], t)!;
        final color = Color.lerp(c1, c2, (sin(t * pi) + 1) / 2)!;

        return Text(
          widget.text,
          style: (widget.style ?? NeonText.headingBold).copyWith(
            color: color,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
            ],
          ),
        );
      },
    );
  }
}
