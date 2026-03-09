import 'dart:convert';

void main() {
  String content = '''```json
{
  "mood": "calm",
  "scores": {
    "positive": 0.5,
    "negative": 0.1,
    "neutral": 0.8
  },
  "response": "I am here."
}
```''';

  final data = content.replaceAll(RegExp(r'```json\n'), '').replaceAll(RegExp(r'```'), '');
  print(jsonDecode(data));
}
