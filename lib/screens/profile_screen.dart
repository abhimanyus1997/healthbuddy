import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttermoji/fluttermoji.dart';
import '../utils/health_service.dart';
import 'avatar_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _gender = 'Male'; // Default

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _apiKeyController.text = prefs.getString('groq_api_key') ?? '';
      _heightController.text = prefs.getString('user_height') ?? '';
      _weightController.text = prefs.getString('user_weight') ?? '';
      _ageController.text = prefs.getString('user_age') ?? '';
      _gender = prefs.getString('user_gender') ?? 'Male';
      _isLoading = false;
    });

    // Auto-prefill if empty
    if (_heightController.text.isEmpty || _weightController.text.isEmpty) {
      _syncFromHealth(auto: true);
    }
  }

  Future<void> _syncFromHealth({bool auto = false}) async {
    if (!mounted) return;
    if (!auto) setState(() => _isLoading = true);

    final healthService = HealthService();
    // If auto, check if we already have permissions to avoid popup spam on load
    // Or just request, as requestPermissions handles checking internally
    bool authorized = await healthService.requestPermissions();

    if (!mounted) return;

    if (authorized) {
      final h = await healthService.getHeight();
      final w = await healthService.getWeight();
      final g = await healthService.getGender();
      final age = await healthService.getAge();

      setState(() {
        if (h != null && _heightController.text.isEmpty) {
          _heightController.text = (h * 100).toStringAsFixed(1);
        }
        if (w != null && _weightController.text.isEmpty) {
          _weightController.text = w.toStringAsFixed(1);
        }
        if (age != null && _ageController.text.isEmpty) {
          _ageController.text = age.toString();
        }
        // Only override gender if we found one
        if (g != null) {
          _gender = g;
        }
      });

      if (!auto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data synced from Health Connect!")),
        );
      }
    } else if (!auto && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Permissions not granted")));
    }

    if (!auto && mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('groq_api_key', _apiKeyController.text);
      await prefs.setString('user_height', _heightController.text);
      await prefs.setString('user_weight', _weightController.text);
      await prefs.setString('user_age', _ageController.text);
      await prefs.setString('user_gender', _gender);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Profile & Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar Section
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AvatarScreen(),
                            ),
                          ).then((_) {
                            // Force rebuild to show updated avatar if needed
                            setState(() {});
                          });
                        },
                        child: FluttermojiCircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AvatarScreen(),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                        child: const Text("Customize Avatar"),
                      ),

                      const SizedBox(height: 30),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Personal Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Center(
                        child: TextButton.icon(
                          onPressed: () => _syncFromHealth(auto: false),
                          icon: const Icon(Icons.sync, color: Colors.blue),
                          label: const Text(
                            "Sync from Health",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildTextField(
                        "Display Name",
                        _nameController,
                        "Enter your name",
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              "Height (cm)",
                              _heightController,
                              "e.g. 175",
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              "Weight (kg)",
                              _weightController,
                              "e.g. 70",
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              "Age",
                              _ageController,
                              "e.g. 25",
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Gender Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Gender",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _gender,
                                isExpanded: true,
                                items: ['Male', 'Female', 'Other'].map((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _gender = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      _buildTextField(
                        "Groq API Key",
                        _apiKeyController,
                        "Enter API Key",
                        obscure: true,
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Save Settings",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Divider(),
                      const SizedBox(height: 10),

                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final healthService = HealthService();
                            bool authorized = await healthService
                                .requestPermissions();

                            if (context.mounted) {
                              if (authorized) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Permissions granted! Syncing data...',
                                    ),
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Permissions Required"),
                                    content: const Text(
                                      "To sync your health data, please enable permissions in Settings.",
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
                            }
                          },
                          icon: const Icon(
                            Icons.security,
                            color: Colors.blueGrey,
                          ),
                          label: const Text(
                            "Grant Health Permissions",
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (label == "Display Name" && (value == null || value.isEmpty)) {
              return 'Please enter a name';
            }
            return null;
          },
        ),
      ],
    );
  }
}
