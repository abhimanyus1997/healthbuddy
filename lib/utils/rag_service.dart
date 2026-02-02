import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class RagService {
  static const String _storageKey = "health_buddy_daily_logs";

  // Save a daily summary
  Future<void> saveDailySummary(DateTime date, String summary) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_storageKey) ?? [];

    // Create a JSON object for the log
    Map<String, dynamic> logEntry = {
      "date": date.toIso8601String(),
      "summary": summary,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    // Remove existing entry for this date if exists to update it
    logs.removeWhere((log) {
      try {
        final decoded = jsonDecode(log);
        final logDate = DateTime.parse(decoded["date"]);
        return logDate.year == date.year &&
            logDate.month == date.month &&
            logDate.day == date.day;
      } catch (e) {
        return false;
      }
    });

    logs.add(jsonEncode(logEntry));
    await prefs.setStringList(_storageKey, logs);
    developer.log("Saved daily summary for ${date.toString().split(' ')[0]}");
  }

  // Search logs
  Future<List<Map<String, dynamic>>> searchHealthLogs(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_storageKey) ?? [];
    List<Map<String, dynamic>> results = [];

    final lowerQuery = query.toLowerCase();

    for (String log in logs) {
      try {
        Map<String, dynamic> decoded = jsonDecode(log);
        String summary = decoded["summary"].toString().toLowerCase();
        String date = decoded["date"].toString();

        if (summary.contains(lowerQuery) || date.contains(lowerQuery)) {
          results.add(decoded);
        }
      } catch (e) {
        developer.log("Error parsing log for search: $e");
      }
    }

    // Sort by date descending
    results.sort((a, b) => b["date"].compareTo(a["date"]));
    return results;
  }

  // Get all logs for context
  Future<List<Map<String, dynamic>>> getAllLogs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_storageKey) ?? [];
    List<Map<String, dynamic>> decodedLogs = [];

    for (String log in logs) {
      try {
        decodedLogs.add(jsonDecode(log));
      } catch (e) {
        // ignore bad logs
      }
    }
    // Sort by date descending
    decodedLogs.sort((a, b) => b["date"].compareTo(a["date"]));
    return decodedLogs;
  }
}
