import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<String?> sendMessage(
    String content, {
    String model = 'openai/gpt-oss-120b',
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null) {
      debugPrint('Error: GROQ_API_KEY not found in .env');
      return "Error: API Key missing";
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "messages": [
            {"role": "user", "content": content},
          ],
          "model": model,
          "temperature": 1,
          "max_completion_tokens": 1024,
          "top_p": 1,
          "stream":
              false, // Simplified for now, can perform streaming if needed
          "stop": null,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('Groq API Error: ${response.statusCode} - ${response.body}');
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint('Exception calling Groq API: $e');
      return "Error: Connection failed";
    }
  }
}
