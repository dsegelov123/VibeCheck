import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/design_system.dart';
import '../../core/voice_call_repository.dart';
import '../../models/companion_persona.dart';
import '../../models/voice_call_log.dart';

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

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        backgroundColor: DesignSystem.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Call Transcripts',
          style: DesignSystem.titleLarge.copyWith(color: DesignSystem.textSlateDeep),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignSystem.textSlateDeep),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: DesignSystem.vibeRed)),
        error: (err, stack) => Center(child: Text('Error loading logs: $err')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_toggle_off, size: 60, color: DesignSystem.textSlateMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No voice calls yet.',
                    style: DesignSystem.bodyMedium.copyWith(color: DesignSystem.textSlateMuted),
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
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DesignSystem.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: DesignSystem.textSlateMuted.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: DesignSystem.vibeRedLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone_callback_rounded, color: DesignSystem.vibeRed),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormat.format(log.startTime),
                              style: DesignSystem.labelBold.copyWith(color: DesignSystem.textSlateDeep),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${log.duration.inMinutes}m ${log.duration.inSeconds % 60}s duration',
                              style: DesignSystem.bodyMedium.copyWith(color: DesignSystem.textSlateMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: DesignSystem.textSlateMuted),
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: DesignSystem.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                       color: DesignSystem.textSlateMuted.withValues(alpha: 0.3),
                       borderRadius: BorderRadius.circular(2),
                    ),
                 ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Call Transcript',
                  style: DesignSystem.titleLarge.copyWith(color: DesignSystem.textSlateDeep),
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
                      style: DesignSystem.bodyMedium.copyWith(
                        color: DesignSystem.textSlateDeep,
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
                      backgroundColor: DesignSystem.vibeRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
