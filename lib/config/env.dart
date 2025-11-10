class Env {
  // OpenAI
  static const openaiApiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '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'); // ← define por --dart-define si quieres
  static const openaiModel =
      String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o-mini');

  // (Deprecado) Groq – ya no se usa
  static const groqApiKey = '';
}
