import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emotional_snapshot.dart';
import '../core/memory_service.dart';

final memoryServiceProvider = Provider((ref) => MemoryService());

final historyProvider = StateNotifierProvider<HistoryNotifier, List<EmotionalSnapshot>>((ref) {
  return HistoryNotifier(ref.watch(memoryServiceProvider));
});

class HistoryNotifier extends StateNotifier<List<EmotionalSnapshot>> {
  final MemoryService _memoryService;

  HistoryNotifier(this._memoryService) : super([]) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    final history = await _memoryService.getHistory();
    state = history;
  }

  Future<void> addSnapshot(EmotionalSnapshot snapshot) async {
    await _memoryService.saveSnapshot(snapshot);
    state = [snapshot, ...state];
  }
}
