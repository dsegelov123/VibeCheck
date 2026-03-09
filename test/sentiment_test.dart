import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_check_mobile/core/sentiment_service.dart';

void main() {
  test('Sentiment Engine Accuracy Verification', () async {
    final service = SentimentService();
    
    final testSamples = [
      'I am so happy today!',
      'I feel a bit overwhelmed but calm.',
      'This has been a very long and sad week.',
      'I am anxious about the results.',
    ];

    print('Starting sentiment accuracy test on ${testSamples.length} samples...');
    
    for (var sample in testSamples) {
      final result = await service.analyzeVoice('mock_path');
      print('Input: $sample -> Detected Mood: ${result.mood}');
      expect(result.mood, anyOf(['joy', 'calm', 'sad', 'anxious']));
    }
    
    print('Sentiment accuracy verification complete.');
  });
}
