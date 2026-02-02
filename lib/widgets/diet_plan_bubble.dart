import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class DietPlanBubble extends StatelessWidget {
  final String
  content; // Expecting formatted text or we could parse JSON if complex
  final String title;

  const DietPlanBubble({super.key, required this.title, required this.content});

  void _sharePlan(BuildContext context) {
    Share.share("$title\n\n$content");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF0), // Light green for healthy feel
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green[800],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.green),
                onPressed: () => _sharePlan(context),
                tooltip: 'Export Diet Plan',
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
