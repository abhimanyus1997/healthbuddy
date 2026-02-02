import 'package:flutter/material.dart';

class BMICard extends StatefulWidget {
  final double? bmi;
  final double? weight;
  final double? height;

  const BMICard({super.key, this.bmi, this.weight, this.height});

  @override
  State<BMICard> createState() => _BMICardState();
}

class _BMICardState extends State<BMICard> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    String bmiCategory = "--";
    Color bmiColor = Colors.grey;

    double bmiValue = widget.bmi ?? 0;

    if (bmiValue > 0) {
      if (bmiValue < 18.5) {
        bmiCategory = "Underweight";
        bmiColor = Colors.blue;
      } else if (bmiValue < 25) {
        bmiCategory = "Normal";
        bmiColor = const Color(0xFFD7FF64);
      } else if (bmiValue < 30) {
        bmiCategory = "Overweight";
        bmiColor = Colors.orange;
      } else {
        bmiCategory = "Obese";
        bmiColor = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "BMI Index",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (widget.bmi != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bmiColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bmiCategory,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: bmiColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: bmiValue),
              duration: const Duration(seconds: 2),
              curve: Curves.easeOut,
              builder: (context, animatedBMI, child) {
                return CustomPaint(
                  size: const Size(200, 100),
                  painter: BMIGaugePainter(
                    bmi: animatedBMI,
                    scoreColor: bmiColor,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: bmiValue),
              duration: const Duration(seconds: 2),
              curve: Curves.easeOut,
              builder: (context, animatedBMI, child) {
                return Text(
                  widget.bmi != null ? animatedBMI.toStringAsFixed(1) : "--",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          Center(
            child: Text(
              "Height: ${widget.height?.toStringAsFixed(1) ?? "-"}m  |  Weight: ${widget.weight?.toStringAsFixed(1) ?? "-"}kg",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class BMIGaugePainter extends CustomPainter {
  final double bmi;
  final Color scoreColor;

  BMIGaugePainter({required this.bmi, required this.scoreColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Draw background track (gray)
    paint.color = Colors.grey.withValues(alpha: 0.2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // Start at 180 deg (PI)
      3.14159, // Sweep 180 deg (PI)
      false,
      paint,
    );

    // Draw Score Arc
    // Map BMI (10-40 range typically) to 0-PI rads
    // 15 = 0 rad, 40 = PI rad approx
    double minBMI = 15;
    double maxBMI = 40;
    double clampedBMI = bmi.clamp(minBMI, maxBMI);
    double normalized = (clampedBMI - minBMI) / (maxBMI - minBMI);
    double sweepAngle = normalized * 3.14159;

    paint.color = scoreColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
