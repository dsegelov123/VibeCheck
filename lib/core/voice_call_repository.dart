import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voice_call_log.dart';

final voiceCallRepositoryProvider = Provider<VoiceCallRepository>((ref) {
  return VoiceCallRepository();
});

class VoiceCallRepository {
  static const String _storageKeyPrefix = 'vibecheck_voice_calls_';

  Future<void> saveCallLog(VoiceCallLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_storageKeyPrefix${log.companionId}';
    
    final existingLogsJson = prefs.getStringList(key) ?? [];
    existingLogsJson.add(log.toJson());
    
    await prefs.setStringList(key, existingLogsJson);
  }

  Future<List<VoiceCallLog>> getCallLogsForCompanion(String companionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_storageKeyPrefix$companionId';
    
    final existingLogsJson = prefs.getStringList(key) ?? [];
    
    return existingLogsJson
        .map((jsonStr) => VoiceCallLog.fromJson(jsonStr))
        // Sort newest first
        .toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
  }
}
