/// Represents a single day's meal plan
class DayMeals {
  final String day;
  final String? breakfast;
  final String? snack1;
  final String? lunch;
  final String? snack2;
  final String? dinner;
  final String? beverages;

  DayMeals({
    required this.day,
    this.breakfast,
    this.snack1,
    this.lunch,
    this.snack2,
    this.dinner,
    this.beverages,
  });

  factory DayMeals.fromJson(Map<String, dynamic> json) {
    return DayMeals(
      day: json['day'] ?? '',
      breakfast: json['breakfast'],
      snack1: json['snack1'] ?? json['morning_snack'],
      lunch: json['lunch'],
      snack2: json['snack2'] ?? json['evening_snack'],
      dinner: json['dinner'],
      beverages: json['beverages'],
    );
  }
}

/// Represents a full weekly meal plan
class MealPlan {
  final String title;
  final List<DayMeals> days;
  final String? note;

  MealPlan({required this.title, required this.days, this.note});

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final daysList =
        (json['days'] as List?)
            ?.map((d) => DayMeals.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];
    return MealPlan(
      title: json['title'] ?? 'Your Meal Plan',
      days: daysList,
      note: json['note'],
    );
  }
}
