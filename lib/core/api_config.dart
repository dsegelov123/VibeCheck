class ApiConfig {
  // ⚠️  Replace these with your actual keys. Do not commit real keys to git!
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String openAiBaseUrl = 'https://api.openai.com/v1';

  static const String elevenLabsApiKey = 'YOUR_ELEVENLABS_API_KEY_HERE';
  // Default Adam voice: pNInz6obbfdqIeCQzWvk
  static const String elevenLabsVoiceId = '6fZce9LFNG3iEITDfqZZ';

  static bool get hasApiKey {
    final isDetected = openAiApiKey != 'YOUR_OPENAI_API_KEY_HERE' && openAiApiKey.length > 20;
    return isDetected;
  }

  static bool get hasElevenLabsKey {
    return elevenLabsApiKey != 'YOUR_ELEVENLABS_API_KEY_HERE' && elevenLabsApiKey.length > 20;
  }
}
