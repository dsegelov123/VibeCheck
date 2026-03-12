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
    const CompanionListView(),
    const ReflectionView(),
    const DashboardView(),
    const GuidedSessionsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      endDrawer: _buildDrawer(context),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: DesignSystem.surface,
        border: Border(
          top: BorderSide(color: DesignSystem.borderColor, width: DesignSystem.borderWidth),
        ),
        boxShadow: DesignSystem.softShadow,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.forum_outlined, 'Companions'),
              _buildNavItem(1, Icons.edit_note_outlined, 'Journal'),
              _buildNavItem(2, Icons.cloud_outlined, 'Weather'),
              _buildNavItem(3, Icons.spa_outlined, 'Sessions'),
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
        if (!isSelected) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? DesignSystem.accent : DesignSystem.textMuted,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: DesignSystem.label.copyWith(
              color: isSelected ? DesignSystem.accent : DesignSystem.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: DesignSystem.background,
      width: MediaQuery.of(context).size.width * 0.8,
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
            iconColor: DesignSystem.error,
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
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
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
                style: DesignSystem.h2,
              ),
              Text(
                'View Profile',
                style: DesignSystem.label,
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
      leading: Icon(icon, color: iconColor ?? DesignSystem.textDeep),
      title: Text(
        title,
        style: DesignSystem.body,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radius)),
    );
  }
}
