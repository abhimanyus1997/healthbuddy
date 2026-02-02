import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttermoji/fluttermoji.dart';
import '../utils/health_service.dart';
import '../utils/rag_service.dart';
import '../widgets/bmi_card.dart';
import '../widgets/sleep_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/parallax_tilt.dart';
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
  int _heartRate = 0;
  int _distance = 0;
  String _sleepDuration = "0h 0m";
  List<SleepDailyData> _weeklySleep = [];
  List<SleepDailyData> _monthlySleep = [];

  double? _bmi;
  double? _weight;
  double? _height;

  bool _isLoading = true;

  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchData();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedName = prefs.getString('user_name');

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
      });
    }
  }

  Future<void> _fetchData() async {
    try {
      developer.log("Fetching health data for dashboard...");
      bool authorized = await _healthService.requestPermissions();
      if (!authorized) {
        developer.log("Permissions denied or Health Connect not available");
        developer.log("Permissions denied or Health Connect not available");
        // Do not auto-show dialog on init, let user trigger it
      }

      // Parallel fetching for performance
      final results = await Future.wait([
        _healthService.getSteps(),
        _healthService.getHeartRate(),
        _healthService.getSleepData(),
        _healthService.getWeeklySleep(),
        _healthService.getDistance(),
        _healthService.getBMI(),
        _healthService.getWeight(),
        _healthService.getHeight(),
      ]);

      // Load fallback data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      double? manualHeight =
          double.tryParse(prefs.getString('user_height') ?? '') != null
          ? double.parse(prefs.getString('user_height')!) /
                100 // cm to m
          : null;
      double? manualWeight = double.tryParse(
        prefs.getString('user_weight') ?? '',
      );

      if (mounted) {
        setState(() {
          _steps = results[0] as int;
          _heartRate = results[1] as int;
          _sleepDuration = results[2] as String;
          _weeklySleep = results[3] as List<SleepDailyData>; // Default 7 Days
          _distance = results[4] as int;

          // Use Health data, otherwise fallback to manual
          _height = (results[7] as double?) ?? manualHeight;
          _weight = (results[6] as double?) ?? manualWeight;

          // Re-calculate BMI if needed using the best available data
          double? fetchedBMI = results[5] as double?;
          if (fetchedBMI != null && fetchedBMI > 0) {
            _bmi = fetchedBMI;
          } else if (_height != null && _weight != null && _height! > 0) {
            _bmi = _weight! / (_height! * _height!);
          } else {
            _bmi = null;
          }
        });
      }
      developer.log("All dashboard data synced.");

      // Save Daily Summary for RAG
      if (mounted) {
        final summary =
            "Steps: $_steps, Sleep: $_sleepDuration, BMI: ${_bmi?.toStringAsFixed(1) ?? 'N/A'}, Weight: ${_weight?.toStringAsFixed(1) ?? 'N/A'}";
        await RagService().saveDailySummary(DateTime.now(), summary);
      }
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

  Future<void> _fetchMonthlySleep() async {
    try {
      final monthly = await _healthService.getSleepHistory(days: 30);
      if (mounted) {
        setState(() {
          _monthlySleep = monthly;
        });
      }
    } catch (e) {
      developer.log("Error fetching monthly sleep: $e");
    }
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
                              // Avatar (Fluttermoji)
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
                                // Using FluttermojiCircleAvatar for the avatar
                                child: FluttermojiCircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[300],
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
                          const SizedBox(height: 10),
                          // Search Bar (Functional)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showSearch(
                                  context: context,
                                  delegate: HealthSearchDelegate(),
                                );
                              },
                              child: Container(
                                height: 30,
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
                      ParallaxTilt(
                        child: SleepCard(
                          sleepDuration: _sleepDuration,
                          weeklySleep: _weeklySleep,
                          monthlySleep: _monthlySleep,
                          onViewModeChanged: (mode) {
                            if (mode == "Monthly" && _monthlySleep.isEmpty) {
                              _fetchMonthlySleep();
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Heart Rate & Activity Row
                      Row(
                        children: [
                          Expanded(
                            child: ParallaxTilt(
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
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ParallaxTilt(
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // BMI Card (Replaces Wellness)
                      ParallaxTilt(
                        child: BMICard(
                          bmi: _bmi,
                          weight: _weight,
                          height: _height,
                        ),
                      ),

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
                                      modelId: "llama-3.3-70b-versatile",
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

class HealthSearchDelegate extends SearchDelegate {
  final RagService _ragService = RagService();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ragService.searchHealthLogs(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No logs found."));
        }

        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final log = results[index];
            final date = DateTime.parse(log['date']);
            final dateStr = "${date.year}-${date.month}-${date.day}";

            return ListTile(
              title: Text(dateStr),
              subtitle: Text(log['summary']),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
