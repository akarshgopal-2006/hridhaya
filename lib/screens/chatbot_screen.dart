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

  /// Offline demo responses keyed by simple keyword matching.
  static const _demoResponses = <String, String>{
    'chest pain':
        'Chest pain can have many causes. If the pain is sharp, spreading to your arm or jaw, and you feel nauseous or short of breath, press the SOS button immediately. For mild discomfort, rest and monitor — but always consult a doctor.',
    'exercise':
        'Regular moderate exercise (150 min/week) strengthens your heart. Start slow and avoid pushing through chest pain. Walking, swimming and cycling are great cardiac-friendly choices.',
    'diet':
        'A heart-healthy diet includes fruits, vegetables, whole grains, lean proteins and healthy fats. Reduce sodium, sugar and processed foods. The Mediterranean diet is particularly beneficial.',
    'blood pressure':
        'Normal blood pressure is around 120/80 mmHg. High blood pressure (hypertension) often has no symptoms but damages arteries over time. Monitor regularly and consult your doctor about medication if needed.',
    'sos':
        'Press the SOS button if you experience sudden severe chest pain, difficulty breathing, sudden numbness or weakness, or if you witness someone collapse. The Safety Loop gives a 30-second countdown to confirm.',
    'stress':
        'Chronic stress raises cortisol levels, which can increase heart rate and blood pressure. Practice deep breathing, meditation, or yoga. Even 10 minutes of calm daily can help your heart.',
    'sleep':
        'Poor sleep (less than 6 hours) increases the risk of heart disease. Aim for 7–9 hours of quality sleep. Avoid caffeine late in the day and maintain a regular sleep schedule.',
    'smoking':
        'Smoking is a major risk factor for heart disease. It damages blood vessels, raises blood pressure your arteriosclerosis. Quitting — even after years — rapidly improves heart health.',
  };

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

    // Simulate a short "thinking" delay.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Find a matching demo response or fall back to a generic one.
    final lower = text.toLowerCase();
    String reply = 'I\'m an offline demo bot. I can answer about: chest pain, exercise, diet, blood pressure, SOS, stress, sleep, and smoking. Try asking about one of these topics!';
    for (final entry in _demoResponses.entries) {
      if (lower.contains(entry.key)) {
        reply = entry.value;
        break;
      }
    }

    setState(() {
      _messages.add(ChatMessage(text: reply, fromUser: false));
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
