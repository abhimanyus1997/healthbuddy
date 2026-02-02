import 'dart:math';
import 'package:flutter/material.dart';

class GravitorBlob extends StatefulWidget {
  const GravitorBlob({super.key});

  @override
  State<GravitorBlob> createState() => _GravitorBlobState();
}

class _GravitorBlobState extends State<GravitorBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<BlobParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize particles
    for (int i = 0; i < 5; i++) {
      _particles.add(
        BlobParticle(
          offset: Offset(
            _random.nextDouble() * 300,
            _random.nextDouble() * 600,
          ),
          velocity: Offset(
            _random.nextDouble() * 2 - 1,
            _random.nextDouble() * 2 - 1,
          ),
          radius: 60 + _random.nextDouble() * 60,
          color: [
            const Color(0xFF009688), // Teal
            const Color(0xFF00C853), // Green
            const Color(0xFFCDDC39), // Lime
          ][_random.nextInt(3)],
        ),
      );
    }
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
      builder: (context, child) {
        return CustomPaint(
          painter: GravitorPainter(
            particles: _particles,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class BlobParticle {
  Offset offset;
  Offset velocity;
  double radius;
  Color color;

  BlobParticle({
    required this.offset,
    required this.velocity,
    required this.radius,
    required this.color,
  });

  void update(Size size) {
    offset += velocity;

    // Bounce off walls
    if (offset.dx < -radius || offset.dx > size.width + radius) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (offset.dy < -radius || offset.dy > size.height + radius) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }
  }
}

class GravitorPainter extends CustomPainter {
  final List<BlobParticle> particles;
  final double animationValue;

  GravitorPainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient Background
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFFE0F2F1), Colors.white],
    );
    final Paint backgroundPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    // Draw Particles with Blur for "Metaball" feel
    for (var particle in particles) {
      particle.update(size);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

      canvas.drawCircle(particle.offset, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GravitorPainter oldDelegate) => true;
}
