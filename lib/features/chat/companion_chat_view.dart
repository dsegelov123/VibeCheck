import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/companion_persona.dart';
import '../../models/chat_message.dart';
import '../../core/chat_service.dart';
import '../../core/audio_service.dart';
import '../../core/sentiment_service.dart';

class CompanionChatView extends ConsumerStatefulWidget {
  final CompanionPersona persona;

  const CompanionChatView({super.key, required this.persona});

  @override
  ConsumerState<CompanionChatView> createState() => _CompanionChatViewState();
}

class _CompanionChatViewState extends ConsumerState<CompanionChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioService _audioService = AudioService();
  bool _isTyping = false;
  bool _isRecording = false;
  
  @override
  void initState() {
    super.initState();
    // Messages are now loaded by the provider
  }

  @override
  void dispose() {
    _audioService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isTyping = true); // Optimistic UI
    
    _scrollToBottom();

    await ref.read(chatMessagesProvider(widget.persona.id).notifier)
      .sendMessage(text, widget.persona);

    if (mounted) {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop and transcribe
      setState(() {
         _isRecording = false;
         _isTyping = true; // Show typing while transcribing
      });
      final path = await _audioService.stopRecording();
      if (path != null) {
        try {
          // Uses Whisper from SentimentService to transcribe
          final sentimentService = ref.read(sentimentServiceProvider);
          // We need a robust transcription method, for now we will cheat and use SentimentService's internal transcribe method by calling analyzeVoice briefly
          // But actually analyzeVoice does transcription + AI analysis. 
          // Let's create a dedicated transcribeAudio method in SentimentService
          final transcript = await sentimentService.transcribeAudioRaw(path);
          if (transcript.isNotEmpty) {
             _sendMessage(transcript);
          } else {
             setState(() => _isTyping = false);
          }
        } catch (e) {
          debugPrint('Recording error: $e');
          setState(() => _isTyping = false);
        }
      }
    } else {
      await _audioService.startRecording();
      setState(() => _isRecording = true);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.persona.id}',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: Colors.black12, width: 1),
              ),
              child: const Icon(Icons.person, size: 24, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.persona.name,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Online',
                style: TextStyle(
                  color: Color(0xFF10B981), // Emerald
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
          onPressed: () {},
        ),
      ],
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
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: Colors.black12, width: 1),
              ),
              child: const Icon(Icons.person, size: 18, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6366F1) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          if (isMe) const SizedBox(width: 40), // Spacing for user messages
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
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
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildDot(int delay) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF94A3B8),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF94A3B8), size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black12, width: 1),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(_textController.text.trim()),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
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
                } else {
                   _toggleRecording();
                }
             },
             child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : const Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: _isRecording 
                 ? const Icon(Icons.stop_rounded, color: Colors.white).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 500.ms)
                 : const Icon(Icons.mic_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
