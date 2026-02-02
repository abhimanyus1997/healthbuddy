import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chart_data.dart';
import '../models/meal_plan.dart';
import '../utils/groq_service.dart';
import '../utils/rag_service.dart';
import '../widgets/chart_message_bubble.dart';
import '../widgets/meal_plan_table.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String modelName;
  final String modelId;

  const ChatScreen({super.key, required this.modelName, required this.modelId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroqService _groqService = GroqService();
  final RagService _ragService = RagService();

  final List<Map<String, String>> _messages = [];

  bool _isLoading = false;
  bool _contextLoaded = false;
  String? _ragContext;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final logs = await _ragService.getAllLogs();

    const int maxLogs = 5;
    String contextData = logs
        .take(maxLogs)
        .map((l) {
          return "Date: ${l['date'].toString().split('T')[0]}, Summary: ${l['summary']}";
        })
        .join("\n");

    final prefs = await SharedPreferences.getInstance();
    final String age = prefs.getString('user_age') ?? 'Unknown';
    final String height = prefs.getString('user_height') ?? 'Unknown';
    final String weight = prefs.getString('user_weight') ?? 'Unknown';
    final String gender = prefs.getString('user_gender') ?? 'Unknown';

    if (contextData.isNotEmpty) {
      _ragContext =
          "User Profile: Age: $age, Height: ${height}cm, Weight: ${weight}kg, Gender: $gender.\n"
          "Recent Health Data:\n$contextData\n\n";
    } else {
      _ragContext =
          "User Profile: Age: $age, Height: ${height}cm, Weight: ${weight}kg, Gender: $gender.\n"
          "No history data available yet.";
    }

    // Structured Output Instructions
    const String structuredOutputInstruction = """
IMPORTANT: When the user asks for a diet plan or meal plan, you MUST respond ONLY with a valid JSON object.
Structure:
{
  "type": "meal_plan",
  "title": "Weekly Vegetarian Diet Plan",
  "days": [
    {
      "day": "Monday",
      "breakfast": "Oatmeal with fruits",
      "snack1": "Mixed nuts",
      "lunch": "Dal with rice and sabzi",
      "snack2": "Apple",
      "dinner": "Chapati with paneer"
    },
    ... more days ...
  ],
  "note": "Optional tip"
}

When the user asks for a chart or visualization, respond ONLY with a valid JSON object:
{
  "type": "chart",
  "chart_type": "bar",
  "title": "Chart Title",
  "data": [{"label": "Label1", "value": 10}, {"label": "Label2", "value": 20}],
  "color": "#4CAF50"
}
""";

    setState(() {
      _messages.add({
        "role": "system",
        "content":
            "You are NutriGPT, an AI health assistant. $_ragContext\n\nKeep answers concise, encouraging, and actionable.\n$structuredOutputInstruction",
      });
      _contextLoaded = true;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    _controller.clear();

    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _isLoading = true;
    });
    _scrollToBottom();

    // Detect if we should request structured output
    final lowerMsg = userMessage.toLowerCase();
    Map<String, dynamic>? responseFormat;

    if (lowerMsg.contains("diet") ||
        lowerMsg.contains("meal plan") ||
        lowerMsg.contains("food plan")) {
      responseFormat = {
        "type": "json_schema",
        "json_schema": {
          "name": "meal_plan_response",
          "schema": {
            "type": "object",
            "properties": {
              "type": {"type": "string"}, // Removed const
              "title": {"type": "string"},
              "days": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "day": {"type": "string"},
                    "breakfast": {"type": "string"},
                    "snack1": {"type": "string"},
                    "lunch": {"type": "string"},
                    "snack2": {"type": "string"},
                    "dinner": {"type": "string"},
                  },
                  "required": ["day"],
                },
              },
              "note": {"type": "string"},
            },
            "required": ["type", "title", "days"],
          },
          "strict": false,
        },
      };
    } else if (lowerMsg.contains("chart") ||
        lowerMsg.contains("graph") ||
        lowerMsg.contains("plot")) {
      responseFormat = {
        "type": "json_schema",
        "json_schema": {
          "name": "chart_response",
          "schema": {
            "type": "object",
            "properties": {
              "type": {"type": "string"}, // Removed const
              "chart_type": {
                "type": "string",
              }, // Removed enum for better validation error handling
              "title": {"type": "string"},
              "data": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "label": {"type": "string"},
                    "value": {"type": "number"},
                  },
                  "required": ["label", "value"],
                },
              },
              "color": {"type": "string"},
            },
            "required": ["type", "chart_type", "title", "data"],
          },
          "strict": false,
        },
      };
    }

    // Determine which model to use based on intent
    String modelToUse = "llama-3.3-70b-versatile";
    if (responseFormat != null) {
      modelToUse = "openai/gpt-oss-20b";
    }

    String? response = await _groqService.sendMessage(
      _messages,
      model: modelToUse,
      responseFormat: responseFormat,
    );

    // Fail-safe: If JSON validation failed (Error 400), retry WITHOUT responseFormat
    if (response != null && response.startsWith("Error: 400")) {
      developer.log(
        "JSON Validation Failed. Retrying with plain text using llama-3.3...",
      );
      response = await _groqService.sendMessage(
        _messages,
        model: "llama-3.3-70b-versatile",
        responseFormat: null, // Clear response format
      );
    }

    developer.log("RAW LLM RESPONSE: $response");

    if (mounted) {
      _handleResponse(response);
    }
  }

  void _handleResponse(String? response) {
    if (response == null) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": "Error: No response from NutriGPT.",
        });
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    // Try to parse as JSON
    if (response.trim().startsWith('{')) {
      try {
        final json = jsonDecode(response) as Map<String, dynamic>;
        final type = json['type'] as String?;

        if (type == 'meal_plan') {
          setState(() {
            _messages.add({"role": "meal_plan", "content": response});
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        } else if (type == 'chart') {
          // Convert to chart format
          final chartJson = {
            "type": json['chart_type'] ?? 'bar',
            "title": json['title'],
            "data": json['data'],
            "color": json['color'],
          };
          setState(() {
            _messages.add({"role": "chart", "content": jsonEncode(chartJson)});
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      } catch (e) {
        developer.log("JSON parse error: $e");
      }
    }

    // Fallback: regular text response
    setState(() {
      _messages.add({"role": "assistant", "content": response});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.modelName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_contextLoaded)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    "Personalized",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final role = message['role'];

                  if (role == 'system') return const SizedBox.shrink();

                  // Meal Plan Handling
                  if (role == 'meal_plan') {
                    try {
                      final mealPlan = MealPlan.fromJson(
                        jsonDecode(message['content']!),
                      );
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.95,
                          child: MealPlanTable(
                            mealPlan: mealPlan,
                            modelName: widget.modelName,
                          ),
                        ),
                      );
                    } catch (e) {
                      return Text("Error displaying meal plan: $e");
                    }
                  }

                  // Chart Handling
                  if (role == 'chart') {
                    try {
                      final chartData = ChartData.fromJson(
                        jsonDecode(message['content']!),
                      );
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: ChartMessageBubble(
                            chartData: chartData,
                            modelName: widget.modelName,
                          ),
                        ),
                      );
                    } catch (e) {
                      return Text("Error displaying chart: $e");
                    }
                  }

                  final isUser = role == 'user';

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFFD7FF64), Color(0xFFC7B9FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: isUser ? const Color(0xFF1A1A1A) : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(24),
                          topRight: const Radius.circular(24),
                          bottomLeft: Radius.circular(isUser ? 24 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isUser
                          ? Text(
                              message['content']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : StreamingTextMarkdown.chatGPT(
                              text: message['content']!,
                              theme: StreamingTextTheme(
                                textStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                              onComplete: _scrollToBottom,
                            ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const TypingIndicator(),
                  ),
                ),
              ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
