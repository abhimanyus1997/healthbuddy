import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Activity history",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    "Current goal: ",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const Text(
                    "Lose Weight",
                    style: TextStyle(
                      color: Color(0xFF009688),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    _buildTab("Progress", true),
                    const SizedBox(width: 30),
                    _buildTab("Insights", false),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Daily Goal Card
              Row(
                children: [
                  // Circular Progress
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Stack(
                      children: [
                        const Center(
                          child: CircularProgressIndicator(
                            value: 0.75, // Mock valid
                            strokeWidth: 8,
                            backgroundColor: Color(0xFFE0F2F1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF009688),
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.teal[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "700 kc",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        "Everyday Goal",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "603 kc",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        "Average Progress",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.bar_chart,
                    color: Color(0xFF009688),
                  ), // Placeholder for mini chart
                ],
              ),

              const SizedBox(height: 40),

              // Great Progress Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Great Progress!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "It looks like you are on track. Please continue to follow your daily plan.",
                            style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right Chart
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        children: [
                          const SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: 0.65,
                              strokeWidth: 12,
                              backgroundColor: Color(0xFFE0F2F1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF009688),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  "From 80 kg",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "-5 kg",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF009688),
                                  ),
                                ),
                                Text(
                                  "To 75 kg",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rocket Icon simulated
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Icon(
                              Icons.rocket_launch,
                              color: Colors.orangeAccent,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF009688) : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        if (isSelected)
          Container(
            height: 3,
            width: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF009688),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
