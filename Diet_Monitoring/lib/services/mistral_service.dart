import 'dart:convert';
import 'package:http/http.dart' as http;

class MistralService {
  static const String _baseUrl = 'https://api.mistral.ai/v1';

  Future<String> chat(String apiKey, String userMessage) async {
    if (apiKey.isEmpty) {
      throw Exception('Mistral API key not set');
    }

    try {
      final uri = Uri.parse('$_baseUrl/chat/completions');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'mistral-small-latest',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful health and fitness assistant named VitalTrack Assistant. 
You help users with:
- Nutrition and diet advice
- Workout and exercise recommendations
- General health and wellness tips
- Recipe suggestions based on ingredients

Be friendly, concise, and helpful. If you don't know something, say so.''',
            },
            {
              'role': 'user',
              'content': userMessage,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get response: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final choices = data['choices'] as List?;
      
      if (choices == null || choices.isEmpty) {
        throw Exception('No response from AI');
      }

      return choices[0]['message']['content'] as String;
    } catch (e) {
      rethrow;
    }
  }
}