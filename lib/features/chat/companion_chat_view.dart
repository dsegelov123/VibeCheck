import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../core/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/companion_persona.dart';
import '../../models/chat_message.dart';
import '../../core/chat_service.dart';
import '../../core/components/vibe_scaffold.dart';
import 'dialing_view.dart';
import 'call_history_view.dart';

class CompanionChatView extends ConsumerStatefulWidget {
  final CompanionPersona persona;

  const CompanionChatView({super.key, required this.persona});

  @override
  ConsumerState<CompanionChatView> createState() => _CompanionChatViewState();
}

class _CompanionChatViewState extends ConsumerState<CompanionChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isTyping = true);

    _scrollToBottom();

    await ref.read(chatMessagesProvider(widget.persona.id).notifier)
      .sendMessage(text, widget.persona);

    if (mounted) {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }



  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.persona.id));
    final showStarters = messages.length <= 1;

    return VibeScaffold(
      title: widget.persona.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.receipt_long_rounded),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CallHistoryView(persona: widget.persona)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone_rounded),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DialingView(persona: widget.persona)),
          ),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (showStarters) _buildStarterChips(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildStarterChips() {
    final startersAsync = ref.watch(starterChipsProvider(widget.persona.id));

    return startersAsync.when(
      loading: () => const SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (starters) {
        if (starters.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: starters.asMap().entries.map((entry) {
              final chip = entry.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _textController.text = chip;
                  _sendMessage(chip);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: AppTheme.cardDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: DesignSystem.accent.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chip,
                        style: DesignSystem.label,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }


  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.accent.withValues(alpha: 0.1),
                border: Border.all(color: DesignSystem.accent.withValues(alpha: 0.1), width: 1),
              ),
              child: const Icon(Icons.person, size: 18, color: DesignSystem.accent),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppTheme.cardDecoration(
                color: isMe ? DesignSystem.accent.withValues(alpha: 0.1) : DesignSystem.surface,
                borderRadius: BorderRadius.circular(DesignSystem.radius),
              ).copyWith(
                border: Border.all(
                  color: isMe ? DesignSystem.accent.withValues(alpha: 0.2) : DesignSystem.borderColor,
                  width: 1,
                ),
              ),
              child: Text(
                message.text,
                style: DesignSystem.body.copyWith(
                  color: DesignSystem.textDeep,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: AppTheme.cardDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                _buildDot(150),
                _buildDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delay) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: DesignSystem.accent.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat())
     .scaleXY(begin: 0.5, end: 1.2, duration: 400.ms, delay: delay.ms, curve: Curves.easeInOutSine)
     .then(duration: 400.ms).scaleXY(begin: 1.2, end: 0.5, curve: Curves.easeInOutSine);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: DesignSystem.background,
        boxShadow: DesignSystem.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: DesignSystem.textMuted, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppTheme.cardDecoration(
                borderRadius: BorderRadius.circular(DesignSystem.radius),
                showBorder: true,
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(_textController.text.trim()),
                style: DesignSystem.body,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: DesignSystem.label,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
             onTap: () {
                HapticFeedback.lightImpact();
                if (_textController.text.isNotEmpty) {
                   _sendMessage(_textController.text.trim());
                }
             },
             child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignSystem.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.accent.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: DesignSystem.surface),
            ),
          ),
        ],
      ),
    );
  }
}


