import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/design_system.dart';
import '../../core/voice_call_repository.dart';
import '../../models/companion_persona.dart';
import '../../models/voice_call_log.dart';
import '../../core/app_theme.dart';
import '../../core/components/vibe_scaffold.dart';

final voiceCallLogsProvider = FutureProvider.family<List<VoiceCallLog>, String>((ref, companionId) async {
  final repo = ref.read(voiceCallRepositoryProvider);
  return repo.getCallLogsForCompanion(companionId);
});

class CallHistoryView extends ConsumerWidget {
  final CompanionPersona persona;

  const CallHistoryView({super.key, required this.persona});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(voiceCallLogsProvider(persona.id));

    return VibeScaffold(
      title: 'Call Transcripts',
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: DesignSystem.body)),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 48, color: DesignSystem.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No voice calls yet.',
                    style: DesignSystem.label,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final dateFormat = DateFormat('MMM d, y, h:mm a');
              
              return GestureDetector(
                onTap: () => _showTranscriptModal(context, log),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: DesignSystem.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone_callback_rounded, color: DesignSystem.accent, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormat.format(log.startTime),
                              style: DesignSystem.h2.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log.duration.inMinutes}m ${log.duration.inSeconds % 60}s duration',
                              style: DesignSystem.label,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: DesignSystem.textMuted),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showTranscriptModal(BuildContext context, VoiceCallLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignSystem.background.withValues(alpha: 0.0),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: AppTheme.cardDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                 child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                       color: DesignSystem.textMuted.withValues(alpha: 0.2),
                       borderRadius: BorderRadius.circular(2),
                    ),
                 ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Call Transcript',
                  style: DesignSystem.h2,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: DesignSystem.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      log.fullTranscript.isEmpty ? "No words spoken." : log.fullTranscript,
                      style: DesignSystem.body.copyWith(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.accent,
                      foregroundColor: DesignSystem.surface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.buttonRadius),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Close', style: DesignSystem.h2.copyWith(fontSize: 16, color: DesignSystem.surface)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
