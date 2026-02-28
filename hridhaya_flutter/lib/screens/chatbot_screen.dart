import 'package:flutter/material.dart';

import '../services/chatbot_api_service.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  final bool fromApi; // true = GPT response, false = offline/demo

  const ChatMessage({required this.text, required this.fromUser, this.fromApi = false});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // Fixed: removed `const` — a const list cannot be mutated at runtime.
  final List<ChatMessage> _messages = [
    const ChatMessage(
      text:
          'Hi, I am Hridhaya Assistant.\nYou can ask about symptoms, lifestyle and when to press SOS.\n(This is a demo and not a substitute for a doctor.)',
      fromUser: false,
    ),
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  /// Offline demo responses removed — now powered by OpenAI via backend.

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, fromUser: true));
      _sending = true;
      _inputController.clear();
    });
    _scrollToBottom();

    // Call the backend API (which calls OpenAI GPT)
    final response = await ChatbotApiService.sendMessage(message: text);

    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage(
        text: response.reply,
        fromUser: false,
        fromApi: response.fromApi,
      ));
      _sending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF311B92), Color(0xFF1565C0), Color(0xFFB2EBF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hridhaya Chat',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'You can ask about symptoms, lifestyle and when to press SOS.\nThis assistant is only for guidance and does not replace a cardiologist.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator as last item
                    if (index == _messages.length && _sending) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: _TypingIndicator(),
                      );
                    }
                    final m = _messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _Bubble(
                        text: m.text,
                        fromUser: m.fromUser,
                        fromApi: m.fromApi,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18).copyWith(bottom: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type your heart health question…',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide:
                                BorderSide(color: scheme.outlineVariant, width: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 0, width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: _sendMessage,
                      child: Icon(
                        _sending ? Icons.hourglass_bottom_rounded : Icons.send_rounded,
                        color: scheme.primary,
                      ),
                    ),
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

class _Bubble extends StatelessWidget {
  final String text;
  final bool fromUser;
  final bool fromApi;

  const _Bubble({required this.text, required this.fromUser, this.fromApi = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(fromUser ? 18 : 4),
      bottomRight: Radius.circular(fromUser ? 4 : 18),
    );

    final bg = fromUser
        ? scheme.primary
        : Colors.white.withValues(alpha: 0.96);
    final fg = fromUser ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
          // AI / Offline badge for bot messages
          if (!fromUser) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: fromApi
                    ? const Color(0xFF1565C0).withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                fromApi ? '✨ GPT-4o' : '📴 Offline',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: fromApi
                          ? const Color(0xFF1565C0)
                          : Colors.grey[600],
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            const SizedBox(width: 4),
            _Dot(delay: 200),
            const SizedBox(width: 4),
            _Dot(delay: 400),
            const SizedBox(width: 8),
            Text(
              'Thinking…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _anim = Tween(begin: 0.3, end: 1.0).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
