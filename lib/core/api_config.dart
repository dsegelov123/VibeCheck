class ApiConfig {
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String openAiBaseUrl = 'https://api.openai.com/v1';

  static bool get hasApiKey {
    final isDetected = openAiApiKey != 'YOUR_OPENAI_API_KEY_HERE' && openAiApiKey.length > 20;
    return isDetected;
  }
}
