import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'providers/mood_provider.dart';
import 'features/companion/companion_view.dart';
import 'features/home/dashboard_view.dart';
import 'core/supabase_config.dart';
import 'core/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await NotificationService().init();

  runApp(
    const ProviderScope(
      child: VibeCheckApp(),
    ),
  );
}

class VibeCheckApp extends ConsumerWidget {
  const VibeCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'VibeCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const DashboardView(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);
    final colors = AppTheme.getMoodGradient(mood);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Center(
                child: Text(
                  'VibeCheck',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MoodButton(mood: 'joy', icon: Icons.wb_sunny),
                    _MoodButton(mood: 'calm', icon: Icons.spa),
                    _MoodButton(mood: 'sad', icon: Icons.cloud),
                    _MoodButton(mood: 'anxious', icon: Icons.bolt),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodButton extends ConsumerWidget {
  final String mood;
  final IconData icon;

  const _MoodButton({required this.mood, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () => ref.read(moodProvider.notifier).state = mood,
    );
  }
}
