import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<String?> sendMessage(
    List<Map<String, String>> messages, {
    String model = 'openai/gpt-oss-20b',
    Map<String, dynamic>? responseFormat,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Error: GROQ_API_KEY not found in .env');
      return "Error: API Key missing. Please set it in Settings.";
    }

    try {
      // DEBUG LOGGING: Print the exact payload being sent
      developer.log("--- GROQ REQUEST START ---");
      developer.log("Model: $model");
      developer.log("Messages Payload: ${jsonEncode(messages)}");
      if (responseFormat != null) {
        developer.log("Response Format: ${jsonEncode(responseFormat)}");
      }
      developer.log("--- GROQ REQUEST END ---");

      final body = {
        "messages": messages,
        "model": model,
        "temperature": 0.7,
        "max_completion_tokens": 1024,
        "top_p": 1,
        "stream": false,
        "stop": null,
      };

      if (responseFormat != null) {
        body['response_format'] = responseFormat;
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('Groq API Error: ${response.statusCode} - ${response.body}');
        return "Error: ${response.statusCode} - ${response.reasonPhrase}";
      }
    } catch (e) {
      debugPrint('Exception calling Groq API: $e');
      return "Error: Connection failed";
    }
  }
}
