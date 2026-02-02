import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class ParallaxTilt extends StatefulWidget {
  final Widget child;
  final double intensity; // How strong the tilt is (e.g., 0.1 to 0.5)

  const ParallaxTilt({super.key, required this.child, this.intensity = 0.05});

  @override
  State<ParallaxTilt> createState() => _ParallaxTiltState();
}

class _ParallaxTiltState extends State<ParallaxTilt> {
  double _x = 0;
  double _y = 0;
  StreamSubscription<GyroscopeEvent>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    // Use gyroscope for smooth tilt based on rotation rate
    // We integrate rotation rate to approximate position, with decay to return to center
    _streamSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        // Integrate and decay
        // event.y rotates around Y axis (horizontal tilt) -> contributes to X offset/rotation
        // event.x rotates around X axis (vertical tilt) -> contributes to Y offset/rotation

        // Simple "spring-back" logic: target is 0, we add delta
        // But gyroscope gives rate.
        // A simpler approach for UI parallax often uses Accelerometer to know "down",
        // but Gyro gives nicer "reaction". Let's try simple Accumulation with Decay.

        double currentX = _x + (event.y * widget.intensity);
        double currentY = _y + (event.x * widget.intensity);

        // Decay to center (re-center when stable)
        _x = currentX * 0.95;
        _y = currentY * 0.95;

        // Clamp to avoid extreme flipping
        _x = _x.clamp(-0.2, 0.2);
        _y = _y.clamp(-0.2, 0.2);
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..rotateX(_y) // Rotate X based on vertical tilt
        ..rotateY(_x), // Rotate Y based on horizontal tilt
      alignment: FractionalOffset.center,
      child: Container(
        decoration: BoxDecoration(
          // Enhanced shadow for 3D depth feeling
          // Shadow moves opposite to tilt?
          // Or just static deep shadow to lift it off background
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: -5,
              offset: Offset(
                -_x * 50,
                -_y * 50,
              ), // Shadow moves opposite to tilt
            ),
            // Highlight for Neumorphism edge
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(_x * 20, _y * 20),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
