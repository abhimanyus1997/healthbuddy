import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  // Define the types of data we want to fetch
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  // Define permissions for each type (READ only for now)
  static const List<HealthDataAccess> _permissions = [
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

      // If we don't have permissions, request them
      if (hasPermissions != true) {
        hasPermissions = await _health.requestAuthorization(
          _types,
          permissions: _permissions,
        );
      }
      return hasPermissions ?? false;
    } catch (e) {
      debugPrint(
        "Error requesting permissions (Health Connect might be unavailable): $e",
      );
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
}
