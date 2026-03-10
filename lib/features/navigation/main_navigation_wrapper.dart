import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/dashboard_view.dart';
import '../chat/companion_list_view.dart';
import '../history/reflection_view.dart';
import '../home/guided_sessions_view.dart';
import '../profile/memory_vault_view.dart';
import '../history/trends_view.dart';
import '../../core/auth_service.dart';
import '../../core/design_system.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class MainNavigationWrapper extends ConsumerStatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  ConsumerState<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends ConsumerState<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const CompanionListView(),
    const ReflectionView(),
    const GuidedSessionsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 76,
      decoration: DesignSystem.glassFrosted.copyWith(
        borderRadius: BorderRadius.circular(38),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.forum_rounded, 'Companions'),
              _buildNavItem(2, Icons.edit_note_rounded, 'Journal'),
              _buildNavItem(3, Icons.spa_rounded, 'Sessions'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DesignSystem.vibeRed.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? DesignSystem.vibeRed : DesignSystem.textSlateMuted,
              size: 24,
            ),
            if (isSelected)
              const SizedBox(height: 4),
            if (isSelected)
              Text(
                label,
                style: DesignSystem.labelBold.copyWith(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: DesignSystem.background,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Mood Trends',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrendsView()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.psychology_outlined,
                  title: 'Memory Vault',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoryVaultView()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            iconColor: DesignSystem.errorRed,
            onTap: () {
              Navigator.pop(context);
              ref.read(authServiceProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('images/avatar_female.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alex',
                style: DesignSystem.titleLarge,
              ),
              Text(
                'View Profile',
                style: DesignSystem.labelBold.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? DesignSystem.textSlateDeep),
      title: Text(
        title,
        style: DesignSystem.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
