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
  String _selectedModelId = "openai/gpt-oss-20b";
  String _selectedModelName = "GPT-OSS 20B";

  final List<Map<String, String>> _availableModels = [
    {"id": "openai/gpt-oss-20b", "name": "GPT-OSS 20B (Fast)"},
    {
      "id": "meta-llama/llama-4-scout-17b-16e-instruct",
      "name": "Llama 4 Scout",
    },
    {
      "id": "meta-llama/llama-4-maverick-17b-128e-instruct",
      "name": "Llama 4 Maverick",
    },
    {"id": "llama-3.3-70b-versatile", "name": "Llama 3.3 70B (Smart)"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchData();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedName = prefs.getString('user_name');
    String? storedModel = prefs.getString('selected_model_id');

    if (storedModel != null) {
      final model = _availableModels.firstWhere(
        (m) => m['id'] == storedModel,
        orElse: () => _availableModels[0],
      );
      _selectedModelId = model['id']!;
      _selectedModelName = model['name']!;
    }

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

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select AI Model",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Different models offer different speeds and capabilities.",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              ..._availableModels.map((model) {
                final isSelected = _selectedModelId == model['id'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.purple : Colors.grey,
                  ),
                  title: Text(
                    model['name']!,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('selected_model_id', model['id']!);
                    setState(() {
                      _selectedModelId = model['id']!;
                      _selectedModelName = model['name']!.split(' (')[0];
                    });
                    if (mounted) Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
                                  Text(
                                    _selectedModelName,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Search Bar & Settings
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      showSearch(
                                        context: context,
                                        delegate: HealthSearchDelegate(),
                                      );
                                    },
                                    child: Container(
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        children: [
                                          SizedBox(width: 12),
                                          Icon(
                                            Icons.search,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Search logs...",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _showModelPicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.settings,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
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

                      // Sleep Card
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

                      // BMI Card
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
                            colors: [Color(0xFFD7FF64), Color(0xFFC7B9FF)],
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "NutriGPT",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
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
                                    builder: (context) => ChatScreen(
                                      modelId: _selectedModelId,
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
                                "Chat",
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
