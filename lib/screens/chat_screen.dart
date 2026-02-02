import 'package:flutter/material.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/groq_service.dart';
import '../utils/rag_service.dart';
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

  // Stores UI messages + System context
  final List<Map<String, String>> _messages = [];

  // Separate list for display to hide system prompt if needed
  // But commonly we just filter by role != system in the listview

  bool _isLoading = false;
  bool _contextLoaded = false;
  String? _ragContext;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Load API Key (ensure it's available for service, usually service reads env but if user set it in settings, we might need to handle that)
    // 2. Load RAG Context
    final logs = await _ragService.getAllLogs();

    // Construct Context String
    const int maxLogs = 5; // Limit to last 5 days
    String contextData = logs
        .take(maxLogs)
        .map((l) {
          return "Date: ${l['date'].toString().split('T')[0]}, Summary: ${l['summary']}";
        })
        .join("\n");

    // Load User Demographics
    final prefs = await SharedPreferences.getInstance();
    final String age = prefs.getString('user_age') ?? 'Unknown';
    final String height = prefs.getString('user_height') ?? 'Unknown';
    final String weight = prefs.getString('user_weight') ?? 'Unknown';
    final String gender = prefs.getString('user_gender') ?? 'Unknown';

    if (contextData.isNotEmpty) {
      _ragContext =
          "User Profile: Age: $age, Height: ${height}cm, Weight: ${weight}kg, Gender: $gender.\n"
          "Recent Health Data:\n$contextData\n\n"
          "Use this to provide specific, personalized advice based on their actual trends.";
    } else {
      _ragContext =
          "User Profile: Age: $age, Height: ${height}cm, Weight: ${weight}kg, Gender: $gender.\n"
          "No history data available yet.";
    }

    // Set System Prompt
    setState(() {
      _messages.add({
        "role": "system",
        "content":
            "You are NutriGPT, an AI health assistant. $_ragContext\n\nKeep answers concise, encouraging, and actionable.",
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

    // Prepare history for API (filter out any UI-only internal messages if we had them)
    // currently _messages matches API format exactly

    // We must ensure the apiKey is available. The GroqService currently looks at dotenv.
    // If we want to support the user-entered key from ProfileScreen, we need to pass it or set it.
    // For now, we rely on the implementation in GroqService (env).
    // UPDATE: To support the profile setting, we should read it here and pass to service if possible,
    // but service signature doesn't take key. Assuming env for now or fixed in service.

    final response = await _groqService.sendMessage(
      _messages,
      model: widget.modelId,
    );

    if (mounted) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": response ?? "Error: No response from NutriGPT.",
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
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
          // RAG Status Indicator
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
                  final isUser = message['role'] == 'user';
                  final isSystem = message['role'] == 'system';

                  // Hide system prompt from UI
                  if (isSystem) return const SizedBox.shrink();

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
                            ? null // User: Dark/Black
                            : const LinearGradient(
                                // AI: Lime to Purple
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

            // Interaction Area
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
                        fillColor: Colors.grey[100], // Functional gray
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12, // Slimmer profile
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
                        color: Colors.black, // Consistent with Connect button
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
