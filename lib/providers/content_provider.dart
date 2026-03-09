import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meditation_session.dart';
import '../core/content_service.dart';

final contentService = Provider<ContentService>((ref) {
  return ContentService();
});

final meditationSessionsProvider = FutureProvider<List<MeditationSession>>((ref) async {
  final service = ref.watch(contentService);
  return await service.fetchSessions();
});
