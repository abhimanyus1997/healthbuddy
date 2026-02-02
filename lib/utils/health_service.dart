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
    // Sleep Data Types
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType
        .SLEEP_DEEP, // Android/iOS specific handling might be needed but requesting is safe
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_SESSION, // General session
  ];

  // Define permissions for each type (READ only for now)
  // MUST MATCH LENGTH OF _types
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
  ];

  Future<bool> requestPermissions() async {
    // Check if we have permissions
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

      // Aggregate steps by day
      for (var point in healthData) {
        final date = DateTime(
          point.dateFrom.year,
          point.dateFrom.month,
          point.dateFrom.day,
        );
        int steps = 0;

        // Handle NumericHealthValue
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
    developer.log("Fetching calories from $midnight to $now");

    try {
      // Fetch Active Energy Burned
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

      developer.log("Total calories fetched: $totalCalories");
      return totalCalories.round();
    } catch (e) {
      developer.log("Error fetching calories: $e");
      return 0;
    }
  }

  Future<int> getHeartRate() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    developer.log("Fetching heart rate from $midnight to $now");

    try {
      // Fetch Heart Rate samples
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (data.isEmpty) {
        developer.log("No heart rate data found");
        return 0;
      }

      // Calculate average roughly, or just get the latest
      // Let's get the latest for "Current Heart Rate" feel
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latest = data.first;

      double hr = 0;
      if (latest.value is NumericHealthValue) {
        hr = (latest.value as NumericHealthValue).numericValue.toDouble();
      }

      developer.log("Latest heart rate fetched: $hr");
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
      return totalDist.round(); // in meters
    } catch (e) {
      developer.log("Error fetching distance: $e");
      return 0;
    }
  }

  Future<String> getSleepData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    developer.log("Fetching sleep data from $yesterday to $now");

    try {
      // Fetch Sleep Session/Intervals
      // Removing SLEEP_IN_BED as it caused errors on some devices
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_SESSION],
      );

      if (data.isEmpty) {
        developer.log("No sleep data found");
        return "0h 0m";
      }

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

      developer.log("Total sleep calculated: ${hours}h ${minutes}m");
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
        startTime: midnight.subtract(
          const Duration(days: 365),
        ), // Look back a year
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

  // Modified to support variable days (7 for weekly, 30 for monthly)
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
          // For monthly view, show date number
          if (days > 7) {
            dayName = "${dayStart.day}";
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
          developer.log("Error fetching sleep day $i: $innerError");
          historyData.add(
            SleepDailyData(
              dayName: (days > 7)
                  ? "${dayStart.day}"
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

  // Alias for backward compatibility if needed, using 7 days
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

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Mon";
      case 2:
        return "Tue";
      case 3:
        return "Wed";
      case 4:
        return "Thu";
      case 5:
        return "Fri";
      case 6:
        return "Sat";
      case 7:
        return "Sun";
      default:
        return "";
    }
  }
}
