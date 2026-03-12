import 'package:flutter/material.dart';
import '../design_system.dart';
import '../app_theme.dart';

class VibeScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? endDrawer;

  const VibeScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.showBackButton = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.endDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              leading: showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.padding),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      endDrawer: endDrawer,
    );
  }
}
