import 'dart:math';

import 'package:flutter/material.dart';

import 'neon_theme.dart';

/// A full-screen animated background featuring:
/// - Soft animated radial gradient blobs that drift and pulse.
/// - Floating glowing particles that rise and twinkle.
/// - A radial vignette gradient for depth.
///
/// Drop behind any screen via `Stack(children: [NeonBackground(), ...])`.
class NeonBackground extends StatefulWidget {
  const NeonBackground({
    super.key,
    this.particleCount = 30,
  });

  final int particleCount;

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with TickerProviderStateMixin {
  late final AnimationController _blobController;
  late final AnimationController _particleController;
  late final List<_Particle> _particles;
  late final List<_Blob> _blobs;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = _generateParticles(widget.particleCount);
    _blobs = _generateBlobs();
  }

  @override
  void dispose() {
    _blobController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  List<_Particle> _generateParticles(int count) {
    final rng = Random();
    return List.generate(count, (_) {
      return _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.8 + rng.nextDouble() * 1.5,
        speed: 0.2 + rng.nextDouble() * 0.4,
        phase: rng.nextDouble() * 2 * pi,
        color: [
          NeonColors.cyan,
          NeonColors.purple,
          NeonColors.pink,
          NeonColors.blue,
        ][rng.nextInt(4)],
      );
    });
  }

  List<_Blob> _generateBlobs() {
    return [
      _Blob(
        color: NeonColors.purple,
        baseX: 0.2,
        baseY: 0.15,
        driftX: 0.06,
        driftY: 0.04,
        radiusFactor: 0.5,
        phase: 0,
      ),
      _Blob(
        color: NeonColors.cyan,
        baseX: 0.8,
        baseY: 0.7,
        driftX: 0.05,
        driftY: 0.04,
        radiusFactor: 0.45,
        phase: pi * 0.5,
      ),
      _Blob(
        color: NeonColors.pink,
        baseX: 0.5,
        baseY: 0.45,
        driftX: 0.04,
        driftY: 0.06,
        radiusFactor: 0.35,
        phase: pi,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Color(0xFF0E0E1A),
            NeonColors.bgDark,
          ],
        ),
      ),
      child: Stack(
        children: [
          _buildBlobs(size),
          _buildParticles(size),
          _buildVignette(),
        ],
      ),
    );
  }

  Widget _buildBlobs(Size size) {
    return AnimatedBuilder(
      animation: _blobController,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _BlobPainter(
            blobs: _blobs,
            progress: _blobController.value,
            screenSize: size,
          ),
        );
      },
    );
  }

  Widget _buildParticles(Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _particleController.value,
          ),
        );
      },
    );
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              Colors.transparent,
              NeonColors.bgDark.withValues(alpha: 0.6),
            ],
            stops: const [0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// --- data classes -----------------------------------------------------------

class _Blob {
  _Blob({
    required this.color,
    required this.baseX,
    required this.baseY,
    required this.driftX,
    required this.driftY,
    required this.radiusFactor,
    required this.phase,
  });

  final Color color;
  final double baseX;
  final double baseY;
  final double driftX;
  final double driftY;
  final double radiusFactor;
  final double phase;
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
  final Color color;
}

// --- custom painters --------------------------------------------------------

class _BlobPainter extends CustomPainter {
  _BlobPainter({
    required this.blobs,
    required this.progress,
    required this.screenSize,
  });

  final List<_Blob> blobs;
  final double progress;
  final Size screenSize;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in blobs) {
      final t = progress * 2 * pi + b.phase;

      // Smooth drifting position using sine waves.
      final cx = (b.baseX + sin(t) * b.driftX) * size.width;
      final cy = (b.baseY + cos(t * 0.7) * b.driftY) * size.height;

      // Pulsing radius.
      final baseRadius = b.radiusFactor * size.shortestSide;
      final radius = baseRadius * (0.85 + 0.15 * sin(t * 1.3));

      // Pulsing opacity.
      final opacity = 0.06 + 0.03 * (0.5 + 0.5 * sin(t * 0.9));

      final rect = Rect.fromCircle(
        center: Offset(cx, cy),
        radius: radius,
      );

      // Soft radial gradient blob.
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          b.color.withValues(alpha: opacity),
          b.color.withValues(alpha: opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

      canvas.drawRect(rect.inflate(40), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.progress != progress;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Particle rises upward, wraps around.
      final py = (p.y - progress * p.speed) % 1.0;
      final dy = (py < 0 ? py + 1 : py) * size.height;
      final dx = p.x * size.width;

      // Twinkle alpha.
      final twinkle = 0.15 + 0.2 * (0.5 + 0.5 * sin(progress * 2 * pi + p.phase));

      final paint = Paint()
        ..color = p.color.withValues(alpha: twinkle)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2);

      canvas.drawCircle(Offset(dx, dy), p.radius, paint);

      // Bright core
      final corePaint = Paint()
        ..color = p.color.withValues(alpha: twinkle * 0.9);
      canvas.drawCircle(Offset(dx, dy), p.radius * 0.4, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}
