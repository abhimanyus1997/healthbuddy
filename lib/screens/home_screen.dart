import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/health_service.dart';
import '../widgets/energy_card.dart';
import '../widgets/bmi_card.dart'; // NEW
import '../widgets/wellness_card.dart';
import '../widgets/sleep_card.dart';
import '../widgets/stat_card.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HealthService _healthService = HealthService();

  // Real Data
  int _steps = 0;
  int _calories = 0;
  int _heartRate = 0;
  int _distance = 0;
  String _sleepDuration = "0h 0m";
  List<double> _weeklySteps = [];
  List<SleepDailyData> _weeklySleep = [];
  bool _isLoading = true;

  String _userName = "User";
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchData();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedName = prefs.getString('user_name');
    String? storedPic = prefs.getString('profile_pic_url');

    // If no stored name, fallback to device info
    if (storedName == null || storedName.isEmpty) {
      final deviceInfo = DeviceInfoPlugin();
      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          storedName = androidInfo.model;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          storedName = iosInfo.name;
        }
      } catch (e) {
        developer.log("Error fetching device info: $e");
      }
    }

    if (mounted) {
      setState(() {
        _userName = storedName ?? "User";
        _profilePicUrl = storedPic;
      });
    }
  }

  Future<void> _fetchData() async {
    try {
      developer.log("Fetching health data for dashboard...");
      bool authorized = await _healthService.requestPermissions();
      if (!authorized) {
        developer.log("Permissions denied or Health Connect not available");
        if (mounted) {
          // Show dialog after a slight delay to ensure context is ready if called from init
          Future.delayed(Duration.zero, () => _showPermissionDialog());
        }
      }

      // Parallel fetching for performance
      final results = await Future.wait([
        _healthService.getSteps(),
        _healthService.getCalories(),
        _healthService.getHeartRate(),
        _healthService.getSleepData(),
        _healthService.getWeeklySteps(),
        _healthService.getWeeklySleep(),
        _healthService.getDistance(),
      ]);

      if (mounted) {
        setState(() {
          _steps = results[0] as int;
          _calories = results[1] as int;
          _heartRate = results[2] as int;
          _sleepDuration = results[3] as String;
          _weeklySteps = results[4] as List<double>;
          _weeklySleep = results[5] as List<SleepDailyData>;
          _distance = results[6] as int;
        });
      }
      developer.log("All dashboard data synced.");
    } catch (e, stackTrace) {
      developer.log(
        "Error in _fetchData: $e",
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permissions Required"),
        content: const Text(
          "Health Buddy needs access to your health data (Steps, Sleep, etc.) to function correctly.\n\nPlease enable permissions in Settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light Gray BG like reference
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Avatar
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen(),
                                    ),
                                  ).then(
                                    (_) => _loadUserInfo(),
                                  ); // Refresh on return
                                },
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage:
                                      _profilePicUrl != null &&
                                          _profilePicUrl!.isNotEmpty
                                      ? NetworkImage(_profilePicUrl!)
                                      : null,
                                  child:
                                      _profilePicUrl == null ||
                                          _profilePicUrl!.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hello, $_userName",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  // Removed mock email
                                ],
                              ),
                            ],
                          ),
                          // Search Bar Mock
                          Container(
                            width: 150,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 10),
                                Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "Search...",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        "Health Overview",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Take control of your health today!",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),

                      const SizedBox(height: 25),

                      // Sleep Card (Moved to Top)
                      SleepCard(
                        sleepDuration: _sleepDuration,
                        weeklySleep: _weeklySleep,
                        monthlySleep: _monthlySleep, // New
                        onViewModeChanged: (mode) {
                          setState(() {
                            _sleepViewMode = mode;
                          });
                          if (mode == "Monthly" && _monthlySleep.isEmpty) {
                            _fetchMonthlySleep();
                          }
                        },
                      ),

                      const SizedBox(height: 15),

                      // Heart Rate & Activity Row
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.favorite_border,
                              title: "Heart Rate",
                              value: _heartRate.toString(),
                              unit: "bpm",
                              subTitle: "Avg",
                              subValue: "Latest",
                              rawData: "Source: Health Connect | Now",
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: StatCard(
                              icon: Icons.directions_run,
                              title: "Activity",
                              value: (_steps / 1000).toStringAsFixed(1),
                              unit: "k steps",
                              subTitle: "Dist",
                              subValue:
                                  "${(_distance / 1000).toStringAsFixed(2)} km",
                              rawData: "Source: Health Connect | Now",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // BMI Card (Replaces Wellness)
                      BMICard(bmi: _bmi, weight: _weight, height: _height),

                      const SizedBox(height: 20),

                      // NutriGPT Entry Point
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD7FF64),
                              Color(0xFFC7B9FF),
                            ], // Lime to Purple
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Start Chat with NutriGPT",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "Get personalized Ai health advice.",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChatScreen(
                                      modelId: "llama3-8b-8192",
                                      modelName: "NutriGPT",
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Chat Now",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: null,
    );
  }
}
