import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;
  final DateTime endDate;

  const ActivityHeatmap({
    super.key,
    required this.datasets,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Walking History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Last 90 Days",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 140, // Fixed height for 7 rows (days of week)
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            reverse:
                true, // Show newest on the right (or left if we want standard calendar? Let's try standard)
            // Actually GitHub shows newest on right.
            // Let's scroll horizontal.
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 days per column (Mon-Sun)
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: 91, // Roughly 13 weeks
            itemBuilder: (context, index) {
              // Calculate date for this cell
              // We want to start from endDate and go backwards if reverse: true?
              // Or start from startDate and go forward?
              // GitHub graph: Columns are weeks. Rows are Mon, Tue, Wed...

              // Simplification: Just a grid of boxes for the last ~90 days.
              // Let's do a simple reverse list for now to ensure we see the latest data.
              final date = endDate.subtract(Duration(days: index));
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final count = datasets[normalizedDate] ?? 0;

              return Tooltip(
                message: "${DateFormat('MMM d').format(date)}: $count steps",
                child: Container(
                  decoration: BoxDecoration(
                    color: _getColor(count),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Less",
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
            const SizedBox(width: 5),
            _legendBox(Colors.grey.shade300),
            _legendBox(const Color(0xFFB2DFDB)),
            _legendBox(const Color(0xFF80CBC4)),
            _legendBox(const Color(0xFF26A69A)),
            _legendBox(const Color(0xFF00695C)),
            const SizedBox(width: 5),
            Text(
              "More",
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColor(int count) {
    if (count == 0) return Colors.grey.shade300;
    if (count < 2000) return const Color(0xFFB2DFDB); // 100
    if (count < 5000) return const Color(0xFF80CBC4); // 200
    if (count < 10000) return const Color(0xFF26A69A); // 400
    return const Color(0xFF00695C); // 800 - Deep Teal
  }
}
