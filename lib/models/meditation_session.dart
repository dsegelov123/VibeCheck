class MeditationSession {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String category;
  final String imageUrl;
  final String audioUrl;
  final List<String> colors;

  MeditationSession({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.category,
    required this.imageUrl,
    required this.audioUrl,
    required this.colors,
  });

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'].toString(),
      title: json['title'] ?? 'Untitled Session',
      description: json['description'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 5,
      category: json['category'] ?? 'General',
      imageUrl: json['image_url'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      colors: (json['colors'] as List?)?.map((e) => e.toString()).toList() ?? ['#000000', '#333333'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'category': category,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'colors': colors,
    };
  }
}
