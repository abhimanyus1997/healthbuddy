import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class SleepDailyData {
  final String dayName;
  final double durationHours;
  final String efficiency;
  final String deepSleep;
  final String lightSleep;
  final String remSleep;

  SleepDailyData({
    required this.dayName,
    required this.durationHours,
    required this.efficiency,
    required this.deepSleep,
    required this.lightSleep,
    required this.remSleep,
  });
}

class HealthService {
  final Health _health = Health();

  // Define the types of data we want to fetch
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.DISTANCE_DELTA,
    // HealthDataType.GENDER, // Causes issues on some devices/SDKs
    // Sleep Data Types
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.BIRTH_DATE,
  ];

  // Define permissions for each type (READ only for now)
  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<bool> requestPermissions() async {
    try {
      bool? hasPermissions = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );

      developer.log("Has permissions: $hasPermissions");

      if (hasPermissions != true) {
        developer.log("Requesting authorization for ${_types.length} types...");
        hasPermissions = await _health.requestAuthorization(
          _types,
          permissions: _permissions,
        );
        developer.log("Authorization result: $hasPermissions");
      }
      return hasPermissions ?? false;
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
      return false;
    }
  }

  Future<int> getSteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      int? steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint("Error fetching steps: $e");
      return 0;
    }
  }

  Future<List<HealthDataPoint>> getHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      return await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: _types,
      );
    } catch (e) {
      debugPrint("Error fetching health data: $e");
      return [];
    }
  }

  Future<Map<DateTime, int>> getStepsHistory(int days) async {
    final now = DateTime.now();
    final endDate = now;
    final startDate = now.subtract(Duration(days: days));

    Map<DateTime, int> stepsData = {};

    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate,
        types: [HealthDataType.STEPS],
      );

      for (var point in healthData) {
        final date = DateTime(
          point.dateFrom.year,
          point.dateFrom.month,
          point.dateFrom.day,
        );
        int steps = 0;

        if (point.value is NumericHealthValue) {
          steps = (point.value as NumericHealthValue).numericValue.round();
        }

        stepsData[date] = (stepsData[date] ?? 0) + steps;
      }

      return stepsData;
    } catch (e) {
      developer.log("Error fetching history: $e");
      return {};
    }
  }

  Future<int> getCalories() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      double totalCalories = 0;
      for (var point in data) {
        if (point.value is NumericHealthValue) {
          totalCalories += (point.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }
      return totalCalories.round();
    } catch (e) {
      developer.log("Error fetching calories: $e");
      return 0;
    }
  }

  Future<int> getHeartRate() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (data.isEmpty) return 0;

      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latest = data.first;

      double hr = 0;
      if (latest.value is NumericHealthValue) {
        hr = (latest.value as NumericHealthValue).numericValue.toDouble();
      }
      return hr.round();
    } catch (e) {
      developer.log("Error fetching heart rate: $e");
      return 0;
    }
  }

  Future<int> getDistance() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.DISTANCE_DELTA],
      );

      double totalDist = 0;
      for (var point in data) {
        if (point.value is NumericHealthValue) {
          totalDist += (point.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }
      developer.log("Distance fetched: $totalDist");
      return totalDist.round(); // in meters
    } catch (e) {
      developer.log("Error fetching distance: $e");
      return 0;
    }
  }

  Future<String> getSleepData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_SESSION],
      );

      if (data.isEmpty) return "0h 0m";

      data = _health.removeDuplicates(data);

      int totalMinutes = 0;
      for (var point in data) {
        if (point.type == HealthDataType.SLEEP_ASLEEP ||
            point.type == HealthDataType.SLEEP_SESSION) {
          totalMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
        }
      }

      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;
      return "${hours}h ${minutes}m";
    } catch (e) {
      developer.log("Error fetching sleep: $e");
      return "0h 0m";
    }
  }

  Future<double?> getBMI() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: midnight.subtract(const Duration(days: 365)),
        endTime: now,
        types: [HealthDataType.BODY_MASS_INDEX],
      );
      if (data.isNotEmpty) {
        data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        if (data.first.value is NumericHealthValue) {
          return (data.first.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }
    } catch (e) {
      developer.log("Error fetching BMI: $e");
    }
    return null;
  }

  Future<double?> getWeight() async {
    final now = DateTime.now();
    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(days: 365)),
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );
      if (data.isNotEmpty) {
        data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        if (data.first.value is NumericHealthValue) {
          return (data.first.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }
    } catch (e) {
      developer.log("Error fetching Weight: $e");
    }
    return null;
  }

  Future<double?> getHeight() async {
    final now = DateTime.now();
    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(days: 365)),
        endTime: now,
        types: [HealthDataType.HEIGHT],
      );
      if (data.isNotEmpty) {
        data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        if (data.first.value is NumericHealthValue) {
          return (data.first.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }
    } catch (e) {
      developer.log("Error fetching Height: $e");
    }
    return null;
  }

  Future<List<SleepDailyData>> getSleepHistory({int days = 7}) async {
    final now = DateTime.now();
    List<SleepDailyData> historyData = [];

    try {
      for (int i = 0; i < days; i++) {
        final dayStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(hours: 24));

        try {
          List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
            startTime: dayStart.subtract(const Duration(hours: 12)),
            endTime: dayEnd.subtract(const Duration(hours: 12)),
            types: [
              HealthDataType.SLEEP_ASLEEP,
              HealthDataType.SLEEP_DEEP,
              HealthDataType.SLEEP_LIGHT,
              HealthDataType.SLEEP_REM,
              HealthDataType.SLEEP_SESSION,
            ],
          );
          data = _health.removeDuplicates(data);

          String dayName = _getDayName(dayStart.weekday);
          if (days > 7) {
            dayName =
                "${dayStart.day.toString().padLeft(2, '0')}/${_getMonthName(dayStart.month)}";
          }

          int totalAsleepMinutes = 0;
          int deepMinutes = 0;
          int lightMinutes = 0;
          int remMinutes = 0;

          for (var point in data) {
            int minutes = point.dateTo.difference(point.dateFrom).inMinutes;

            if (point.type == HealthDataType.SLEEP_ASLEEP ||
                point.type == HealthDataType.SLEEP_SESSION) {
              totalAsleepMinutes += minutes;
            }
            if (point.type == HealthDataType.SLEEP_DEEP) {
              deepMinutes += minutes;
            }
            if (point.type == HealthDataType.SLEEP_LIGHT) {
              lightMinutes += minutes;
            }
            if (point.type == HealthDataType.SLEEP_REM) {
              remMinutes += minutes;
            }
          }

          int assumedInBed = totalAsleepMinutes + 30;
          String efficiency = "--";
          if (totalAsleepMinutes > 0) {
            double eff = (totalAsleepMinutes / assumedInBed) * 100;
            efficiency = "${eff.round()}%";
          }

          historyData.add(
            SleepDailyData(
              dayName: dayName,
              durationHours: totalAsleepMinutes / 60.0,
              efficiency: efficiency,
              deepSleep: "${deepMinutes ~/ 60}h ${deepMinutes % 60}m",
              lightSleep: "${lightMinutes ~/ 60}h ${lightMinutes % 60}m",
              remSleep: "${remMinutes ~/ 60}h ${remMinutes % 60}m",
            ),
          );
        } catch (innerError) {
          historyData.add(
            SleepDailyData(
              dayName: (days > 7)
                  ? "${dayStart.day.toString().padLeft(2, '0')}/${_getMonthName(dayStart.month)}"
                  : _getDayName(dayStart.weekday),
              durationHours: 0,
              efficiency: "--",
              deepSleep: "0h 0m",
              lightSleep: "0h 0m",
              remSleep: "0h 0m",
            ),
          );
        }
      }

      return historyData.reversed.toList();
    } catch (e) {
      developer.log("Error fetching sleep history: $e");
      return [];
    }
  }

  Future<List<SleepDailyData>> getWeeklySleep() async {
    return getSleepHistory(days: 7);
  }

  Future<List<double>> getWeeklySteps() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));

    List<double> dailySteps = List.filled(7, 0.0);

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      data = _health.removeDuplicates(data);

      for (var point in data) {
        if (point.value is NumericHealthValue) {
          int steps = (point.value as NumericHealthValue).numericValue.round();
          int dayDiff = point.dateFrom.difference(startDate).inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            dailySteps[dayDiff] += steps;
          }
        }
      }
      return dailySteps;
    } catch (e) {
      developer.log("Error fetching weekly steps: $e");
      return List.filled(7, 0.0);
    }
  }

  Future<String?> getGender() async {
    final now = DateTime.now();
    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(days: 365 * 10)),
        endTime: now,
        types: [HealthDataType.GENDER],
      );
      if (data.isNotEmpty) {
        data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        final point = data.first;
        if (point.value is NumericHealthValue) {
          final val = (point.value as NumericHealthValue).numericValue.toInt();
          if (val == 1) return 'Male';
          if (val == 2) return 'Female';
          if (val == 3) return 'Other';
        }
      }
    } catch (e) {
      developer.log("Error fetching Gender: $e");
    }
    return null;
  }

  Future<int?> getAge() async {
    try {
      final now = DateTime.now();
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: DateTime(1900),
        endTime: now,
        types: [HealthDataType.BIRTH_DATE],
      );

      if (data.isNotEmpty) {
        final bdayPoint = data.first;
        DateTime? birthDate = bdayPoint.dateFrom;

        int age = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
        return age;
      }
    } catch (e) {
      developer.log("Error fetching Age: $e");
    }
    return null;
  }

  String _getDayName(int weekday) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    if (weekday >= 1 && weekday <= 7) return days[weekday - 1];
    return "";
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return "";
  }
}
