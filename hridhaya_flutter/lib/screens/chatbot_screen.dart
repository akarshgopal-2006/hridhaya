import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool fromUser;

  const ChatMessage({required this.text, required this.fromUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = const [
    ChatMessage(
      text:
          'Hi, I am Hridhaya Assistant.\nYou can ask about symptoms, lifestyle and when to press SOS.\n(This is a demo and not a substitute for a doctor.)',
      fromUser: false,
    ),
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, fromUser: true));
      _sending = true;
      _inputController.clear();
    });
    _scrollToBottom();

    final reply = _buildReply(text);
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, fromUser: false));
        _sending = false;
      });
      _scrollToBottom();
    });
  }

  String _buildReply(String raw) {
    final text = raw.toLowerCase();

    if (text.contains('chest') && text.contains('pain')) {
      return 'If chest pain is heavy, lasts more than a few minutes, or spreads to arm, jaw or back,\npress SOS immediately and call emergency services. Do NOT wait to see if it passes.';
    }
    if (text.contains('thud') || text.contains('fall')) {
      return 'A strong thud or fall plus dizziness, blackout or confusion is serious.\nIf you feel unwell after a fall, use Safety Loop or SOS and get checked by a doctor.';
    }
    if (text.contains('bp') ||
        text.contains('blood pressure') ||
        text.contains('pressure')) {
      return 'Keeping blood pressure under control protects your heart.\nLimit salt, avoid smoking, move your body daily and take your BP medicines exactly as prescribed.';
    }
    if (text.contains('sleep')) {
      return 'Most hearts like 7–9 hours of good sleep.\nVery little or very broken sleep can raise BP and trigger rhythm issues over time.';
    }
    if (text.contains('diet') || text.contains('food') || text.contains('eat')) {
      return 'Aim for more colourful vegetables, fruits, whole grains, nuts and less deep‑fried or packaged food.\nSmall swaps every day lower long‑term cardiac risk.';
    }
    if (text.contains('exercise') ||
        text.contains('walk') ||
        text.contains('running')) {
      return 'For many people, 150 minutes per week of moderate activity (like brisk walking) is a good target.\nAlways start slowly and speak to a doctor if you already have heart disease.';
    }
    if (text.contains('stress') ||
        text.contains('anxious') ||
        text.contains('anxiety')) {
      return 'Stress itself can raise heart rate and BP.\nSlow breathing, short walks, talking to someone you trust and regular sleep all help your heart handle stress better.';
    }

    return 'I may not fully understand that question.\nFor anything urgent, especially chest pain, shortness of breath or fainting, press SOS and seek a doctor.\nFor lifestyle questions you can ask about diet, sleep, BP, exercise, stress or when to press SOS.';
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
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _Bubble(text: m.text, fromUser: m.fromUser),
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

  const _Bubble({required this.text, required this.fromUser});

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
      child: Container(
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
    );
  }
}


