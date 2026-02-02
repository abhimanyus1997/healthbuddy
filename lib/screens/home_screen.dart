import 'package:flutter/material.dart';
import '../utils/health_service.dart';
import 'chat_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HealthService _healthService = HealthService();
  int _steps = 0;
  bool _isLoading = true;
  String _deviceName = "User";

  @override
  void initState() {
    super.initState();
    _fetchData();
    _getDeviceName();
  }

  Future<void> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    String name = "User";
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = androidInfo.model; // e.g. "Pixel 5"
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.name; // e.g. "iPhone 13"
      }
    } catch (e) {
      debugPrint("Error fetching device info: $e");
    }

    if (mounted) {
      setState(() {
        _deviceName = name;
      });
    }
  }

  Future<void> _fetchData() async {
    try {
      await _healthService.requestPermissions();
      int steps = await _healthService.getSteps();
      if (mounted) {
        setState(() {
          _steps = steps;
        });
      }
    } catch (e) {
      debugPrint("Error in _fetchData: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi $_deviceName",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Here is your daily stats",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=11',
                      ), // Placeholder
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Insight Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1), // Light teal
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFF009688)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Don't be lazy, you haven't exercised for 3 days",
                          style: TextStyle(color: Colors.teal[800]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Calories",
                        value: "603 kc",
                        color: const Color(0xFF00C853), // Green
                        icon: Icons.local_fire_department,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        title: "Weight",
                        value: "80 kg",
                        color: const Color(0xFF009688), // Teal
                        icon: Icons.monitor_weight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Walking/Steps Card
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009688),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF009688).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Walking",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "$_steps Steps",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Placeholder for Wave/Graph
                      Container(
                        width: 100,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.2,
                          ), // Updated for consistency
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.graphic_eq,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // NutriGPT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "NutriGPT",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text("See all")),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140, // Height for model cards
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildModelCard(
                        "Llama 3",
                        "llama3-70b-8192",
                        Colors.orangeAccent,
                      ),
                      _buildModelCard(
                        "GPT-OSS",
                        "openai/gpt-oss-120b",
                        Colors.purpleAccent,
                      ),
                      _buildModelCard(
                        "Mixtral",
                        "mixtral-8x7b-32768",
                        Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement menu
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.teal),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              const Icon(Icons.more_horiz, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.black12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(String name, String id, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(modelName: name, modelId: id),
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(
          right: 15,
          bottom: 10,
          top: 10,
        ), // Margin for shadow
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
