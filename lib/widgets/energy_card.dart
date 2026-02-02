import 'package:flutter/material.dart';

class EnergyCard extends StatelessWidget {
  final int calories;
  final String? rawData;

  const EnergyCard({super.key, required this.calories, this.rawData});

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
            children: [
              Row(
                children: const [
                  Icon(Icons.flash_on, size: 20, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "Energy Used",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                (calories / 1000)
                    .toStringAsFixed(1)
                    .replaceAll('.', ','), // Format like 2,6
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "k",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              const Text("kcal today", style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          // Bubbles
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Purple Bubble (Left) - Main Activity
                Positioned(
                  left: 0,
                  child: _buildBubble(
                    size: 140,
                    color: const Color(0xFFC7B9FF),
                    text: (calories * 0.6)
                        .round()
                        .toString(), // Mock split for visual
                    subtext: "kcal",
                    textColor: Colors.black,
                  ),
                ),
                // Black Bubble (Right) - Resting?
                Positioned(
                  right: 0,
                  child: _buildBubble(
                    size: 110,
                    color: const Color(0xFF1A1A1A),
                    text: (calories * 0.3).round().toString(),
                    subtext: "kcal",
                    textColor: Colors.white,
                  ),
                ),
                // Lime Bubble (Bottom Center) - Other?
                Positioned(
                  bottom: 0,
                  child: _buildBubble(
                    size: 90,
                    color: const Color(0xFFD7FF64),
                    text: (calories * 0.1).round().toString(),
                    subtext: "kcal",
                    textColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble({
    required double size,
    required Color color,
    required String text,
    required String subtext,
    required Color textColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
