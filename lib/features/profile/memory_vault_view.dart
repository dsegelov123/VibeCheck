import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/user_memory_service.dart';
import '../../models/user_profile.dart';
import '../../models/companion_persona.dart';

class MemoryVaultView extends ConsumerWidget {
  const MemoryVaultView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Memory Vault'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          _buildSectionHeader(context, 'Active Memory', 
            'These facts are currently used by companions to personalize your experience.'),
          _buildFactList(context, ref, profile.activeFacts, isActive: true),
          
          _buildSectionHeader(context, 'Archived Memory', 
            'Older or less relevant facts kept for long-term context.'),
          _buildFactList(context, ref, profile.archivedFacts, isActive: false),
          
          if (profile.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('Your companions haven\'t learned any facts yet.'),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFactDialog(context, ref),
        label: const Text('Add Fact'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildFactList(BuildContext context, WidgetRef ref, List<UserFact> facts, {required bool isActive}) {
    if (facts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('None yet', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final fact = facts[index];
          final persona = CompanionPersona.all.firstWhere(
            (p) => p.id == fact.sourceCompanionId,
            orElse: () => CompanionPersona.all.first,
          );

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundImage: AssetImage(persona.avatarAsset),
                radius: 20,
              ),
              title: Text(fact.text, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Learned by ${persona.name} • ${DateFormat.yMMMd().format(fact.timestamp)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(isActive ? Icons.archive_outlined : Icons.unarchive_outlined, size: 20),
                    tooltip: isActive ? 'Archive' : 'Make Active',
                    onPressed: () => _toggleFactTier(ref, fact, isActive),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteFact(ref, fact, isActive),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: facts.length,
      ),
    );
  }

  void _toggleFactTier(WidgetRef ref, UserFact fact, bool currentlyActive) {
    final profile = ref.read(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    
    if (currentlyActive) {
      final newActive = profile.activeFacts.where((f) => f != fact).toList();
      final newArchived = [fact, ...profile.archivedFacts];
      notifier.state = profile.copyWith(activeFacts: newActive, archivedFacts: newArchived);
    } else {
      final newArchived = profile.archivedFacts.where((f) => f != fact).toList();
      final newActive = [fact, ...profile.activeFacts];
       notifier.state = profile.copyWith(activeFacts: newActive, archivedFacts: newArchived);
    }
    // Update SharedPreferences
    ref.read(userMemoryServiceProvider).saveProfile(ref.read(userProfileProvider));
  }

  void _deleteFact(WidgetRef ref, UserFact fact, bool isActive) {
    final profile = ref.read(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    
    if (isActive) {
      notifier.state = profile.copyWith(activeFacts: profile.activeFacts.where((f) => f != fact).toList());
    } else {
      notifier.state = profile.copyWith(archivedFacts: profile.archivedFacts.where((f) => f != fact).toList());
    }
    ref.read(userMemoryServiceProvider).saveProfile(ref.read(userProfileProvider));
  }

  void _showAddFactDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Memory Fact'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., I love hiking in the rain'),
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newFact = UserFact(
                  text: controller.text.trim(),
                  sourceCompanionId: 'system', // Manually added
                  timestamp: DateTime.now(),
                );
                final profile = ref.read(userProfileProvider);
                ref.read(userProfileProvider.notifier).state = profile.copyWith(
                  activeFacts: [newFact, ...profile.activeFacts],
                );
                ref.read(userMemoryServiceProvider).saveProfile(ref.read(userProfileProvider));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
