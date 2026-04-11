import 'dart:convert';
import 'package:http/http.dart' as http;

class MinimaxDatasource {
  static const _baseUrl = 'https://api.minimax.chat/v1';

  final String apiKey;
  final String groupId;
  final http.Client _client;

  MinimaxDatasource({
    required this.apiKey,
    required this.groupId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<String> translateToChinese(String text) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/text/translate'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'minimax-translate',
        'text': text,
        'source_lang': 'en',
        'target_lang': 'zh',
        'group_id': groupId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['text'] as String;
      }
      throw Exception('Invalid response format from Minimax translation API');
    }

    if (response.statusCode == 429) {
      throw Exception('Minimax API rate limit exceeded. Please try again later.');
    }

    throw Exception('Translation failed: ${response.statusCode} - ${response.body}');
  }

  Future<String> summarize(String text, {int maxTokens = 500}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/text/summarization'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'minimax-abab6',
        'text': text,
        'max_tokens': maxTokens,
        'group_id': groupId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['text'] as String;
      }
      throw Exception('Invalid response format from Minimax summarization API');
    }

    if (response.statusCode == 429) {
      throw Exception('Minimax API rate limit exceeded. Please try again later.');
    }

    throw Exception('Summarization failed: ${response.statusCode} - ${response.body}');
  }
}
