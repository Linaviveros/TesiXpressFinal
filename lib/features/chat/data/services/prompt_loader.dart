import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PromptLoader {
  /// Carga un JSON con claves: { "system": "...", "rubric": "..." }
  static Future<Map<String, String>> load() async {
    final raw = await rootBundle.loadString('assets/prompts/analysis_prompt.json');
    final data = jsonDecode(raw);
    return {
      'system': (data['system'] ?? '').toString(),
      'rubric': (data['rubric'] ?? '').toString(),
    };
  }
}
