import 'package:flutter/material.dart';

class WellnessCard extends StatelessWidget {
  final List<double> weeklySteps; // 7 days of steps

  const WellnessCard({super.key, this.weeklySteps = const []});

  @override
  Widget build(BuildContext context) {
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
            children: const [
              Text(
                "%  Wellness Index",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                "78",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                "%",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7FF64).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "+10%",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Dot Matrix
          // 7 columns x 5 rows?
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (colIndex) {
                // Determine height/intensity based on steps
                // Max steps goal reference, e.g. 10,000
                double steps = 0;
                if (weeklySteps.length > colIndex) {
                  steps = weeklySteps[colIndex];
                }

                // Normalize 0-5 (rows)
                int activeRows = (steps / 2000)
                    .ceil(); // Every 2000 steps = 1 dot
                if (activeRows > 5) activeRows = 5;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (rowIndex) {
                    // rowIndex 0 is top, 4 is bottom
                    // We want to fill from bottom up.
                    // So if rowIndex >= (5 - activeRows), it's active.

                    bool isActive = rowIndex >= (5 - activeRows);

                    // Color Variation
                    Color dotColor = Colors.grey.shade200;
                    if (isActive) {
                      if (rowIndex == 4) {
                        dotColor = const Color(0xFFC7B9FF); // Bottom
                      } else {
                        dotColor = const Color(0xFFC7B9FF).withValues(
                          alpha: 0.6 + (rowIndex * 0.1),
                        ); // Fade slightly up
                      }
                    }

                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
