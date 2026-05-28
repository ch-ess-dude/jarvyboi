// agent_panel.dart — Persistent overlay panel for the AI agent.
// Summon via long-press on the nav bar (wired in main_nav.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../database/database.dart';
import 'agent_provider.dart';
import 'sphere_painter.dart';

class AgentPanel extends ConsumerStatefulWidget {
  final bool isOnboarding;

  const AgentPanel({super.key, this.isOnboarding = false});

  @override
  ConsumerState<AgentPanel> createState() => _AgentPanelState();
}

class _AgentPanelState extends ConsumerState<AgentPanel>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _stt = SpeechToText();

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  bool _sttAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutExpo));
    _slideCtrl.forward();
    _initStt();

    // Onboarding: Jarvis speaks first.
    if (widget.isOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jarvisGreet());
    }
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize(onError: (_) {});
    if (mounted) setState(() => _sttAvailable = ok);
  }

  Future<void> _jarvisGreet() async {
    final db = ref.read(dbProvider);
    await ref.read(agentServiceProvider).send(
          userMessage:
              'Hello, I am ready for onboarding. Please start the conversation.',
          db: db,
          onboarding: true,
        );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _stt.stop();
    super.dispose();
  }

  void _close() {
    _slideCtrl.reverse().then((_) {
      if (mounted) {
        ref.read(agentPanelVisibleProvider.notifier).hide();
      }
    });
  }

  Future<void> _send() async {
    final msg = _textCtrl.text.trim();
    if (msg.isEmpty) return;
    _textCtrl.clear();

    final db = ref.read(dbProvider);
    await ref.read(agentServiceProvider).send(
          userMessage: msg,
          db: db,
          onboarding: widget.isOnboarding,
        );

    // Scroll to bottom after response.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (!_sttAvailable) return;
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      ref.read(agentStateProvider.notifier).setIdle();
    } else {
      setState(() => _isListening = true);
      ref.read(agentStateProvider.notifier).setListening();
      await _stt.listen(
        onResult: (result) {
          _textCtrl.text = result.recognizedWords;
          if (result.finalResult) {
            setState(() => _isListening = false);
            ref.read(agentStateProvider.notifier).setIdle();
            _send();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_US',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentStateProvider);
    final conversation = ref.watch(conversationProvider);
    final streamingText = ref.watch(streamingTextProvider);
    final isProcessing =
        state == AgentState.processing || state == AgentState.responding;

    return SlideTransition(
      position: _slideAnim,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111214),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(state),
              Expanded(child: _buildConversation(conversation, streamingText)),
              _buildInput(isProcessing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AgentState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          AnimatedSphere(state: state, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jarvis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _stateLabel(state),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.isOnboarding)
            GestureDetector(
              onTap: _close,
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.35),
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversation(
      List<AgentMessage> conversation, String streamingText) {
    final allMsgs = [
      ...conversation,
      if (streamingText.isNotEmpty)
        AgentMessage(
          role: 'assistant',
          content: streamingText,
          timestamp: DateTime.now(),
        ),
    ];

    if (allMsgs.isEmpty) {
      return Center(
        child: Text(
          'Ask me anything about your day.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: allMsgs.length,
      itemBuilder: (_, i) => _MessageBubble(message: allMsgs[i]),
    );
  }

  Widget _buildInput(bool isProcessing) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Message Jarvis…',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.28), fontSize: 15),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => _send(),
              enabled: !isProcessing,
            ),
          ),
          const SizedBox(width: 8),
          if (_sttAvailable)
            _InputButton(
              icon: _isListening ? Icons.stop_rounded : Icons.mic_rounded,
              active: _isListening,
              onTap: _toggleListening,
            ),
          const SizedBox(width: 6),
          _InputButton(
            icon: Icons.arrow_upward_rounded,
            active: false,
            onTap: isProcessing ? null : _send,
          ),
        ],
      ),
    );
  }

  String _stateLabel(AgentState s) {
    switch (s) {
      case AgentState.idle:
        return 'ready';
      case AgentState.listening:
        return 'listening…';
      case AgentState.processing:
        return 'thinking…';
      case AgentState.responding:
        return 'responding…';
      case AgentState.offline:
        return 'offline';
    }
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final AgentMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF4DD9C0).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isUser ? 0.9 : 0.82),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Input button ──────────────────────────────────────────────────────────────
class _InputButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  const _InputButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF4DD9C0).withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.2)
              : active
                  ? const Color(0xFF4DD9C0)
                  : Colors.white.withValues(alpha: 0.6),
          size: 20,
        ),
      ),
    );
  }
}
