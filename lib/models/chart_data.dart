class ChartData {
  final String type; // 'bar', 'line', 'pie'
  final String title;
  final List<ChartPoint> data;
  final String? color;

  ChartData({
    required this.type,
    required this.title,
    required this.data,
    this.color,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      type: json['type'] ?? 'bar',
      title: json['title'] ?? '',
      data:
          (json['data'] as List?)
              ?.map((e) => ChartPoint.fromJson(e))
              .toList() ??
          [],
      color: json['color'],
    );
  }
}

class ChartPoint {
  final String label;
  final double value;

  ChartPoint({required this.label, required this.value});

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
