import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey;
  final String model;
  final String baseUrl;

  OpenAIService({
    required this.apiKey,
    required this.model,
    this.baseUrl = 'https://api.openai.com/v1',
  });

  Uri _endpoint(String path) => Uri.parse('$baseUrl/$path');

  /// Chat Completions (mensajes estilo OpenAI: system/user/assistant)
  Future<String> chatComplete({
    required String systemPrompt,
    required String userContent,
    List<Map<String, String>> history = const [],
    double temperature = 0.2,
    int? maxTokens,
  }) async {
    final uri = _endpoint('chat/completions');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history, // [{role: 'user'|'assistant', content: '...'}, ...]
      {'role': 'user', 'content': userContent},
    ];

    final body = {
      'model': model,
      'messages': messages,
      'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
    };

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      final snippet = resp.body.length > 800 ? resp.body.substring(0, 800) : resp.body;
      throw Exception('OpenAI error ${resp.statusCode}: $snippet');
    }

    final data = jsonDecode(resp.body);
    final text = data['choices']?[0]?['message']?['content'];
    return (text is String) ? text : '';
  }
}
