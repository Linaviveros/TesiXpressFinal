// lib/features/chat/data/services/groq_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  final String apiKey;
  final String model;
  final String baseUrl;

  GroqService({
    required this.apiKey,
    this.model = 'llama-3.3-70b-versatile',
    this.baseUrl = 'https://api.groq.com/openai/v1',
  });

  Uri _endpoint(String path) => Uri.parse('$baseUrl/$path');

  /// Llama al endpoint OpenAI-compatible de Groq (chat/completions).
  /// Envía mensajes system + user (y, opcionalmente, un "contexto" aplanado para memoria efímera).
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.2,
    int? maxTokens,
  }) async {
    final uri = _endpoint('chat/completions');
    final body = {
      "model": model,
      "temperature": temperature,
      if (maxTokens != null) "max_tokens": maxTokens,
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userPrompt}
      ]
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
      final snippet = resp.body.length > 1000 ? resp.body.substring(0, 1000) : resp.body;
      throw Exception('Groq error ${resp.statusCode}: $snippet');
    }

    final data = jsonDecode(resp.body);
    final text = data['choices']?[0]?['message']?['content'] ?? '';
    return text is String ? text : '';
  }
}
