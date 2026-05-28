// agent_provider.dart — Riverpod state for the Agent Panel.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../services/ollama_service.dart';
import '../../services/context_builder.dart';

// ── Agent state enum ──────────────────────────────────────────────────────────
enum AgentState { idle, listening, processing, responding, offline }

// ── Conversation message ──────────────────────────────────────────────────────
class AgentMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const AgentMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, String> toHistoryMap() => {'role': role, 'content': content};
}

// ── Agent notifier ────────────────────────────────────────────────────────────
class AgentNotifier extends StateNotifier<AgentState> {
  AgentNotifier() : super(AgentState.idle);

  void setIdle() => state = AgentState.idle;
  void setListening() => state = AgentState.listening;
  void setProcessing() => state = AgentState.processing;
  void setResponding() => state = AgentState.responding;
  void setOffline() => state = AgentState.offline;
}

// ── Conversation notifier ─────────────────────────────────────────────────────
class ConversationNotifier extends StateNotifier<List<AgentMessage>> {
  ConversationNotifier() : super([]);

  void addMessage(AgentMessage msg) {
    state = [...state, msg];
  }

  void clear() => state = [];
}

// ── Streaming response notifier ───────────────────────────────────────────────
class StreamingTextNotifier extends StateNotifier<String> {
  StreamingTextNotifier() : super('');

  void clear() => state = '';
  void append(String token) => state = state + token;
}

// ── Panel visibility ──────────────────────────────────────────────────────────
class PanelVisibilityNotifier extends StateNotifier<bool> {
  PanelVisibilityNotifier() : super(false);

  void show() => state = true;
  void hide() => state = false;
  void toggle() => state = !state;
}

// ── Providers ─────────────────────────────────────────────────────────────────
final agentStateProvider =
    StateNotifierProvider<AgentNotifier, AgentState>((_) => AgentNotifier());

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, List<AgentMessage>>(
        (_) => ConversationNotifier());

final streamingTextProvider =
    StateNotifierProvider<StreamingTextNotifier, String>(
        (_) => StreamingTextNotifier());

final agentPanelVisibleProvider =
    StateNotifierProvider<PanelVisibilityNotifier, bool>(
        (_) => PanelVisibilityNotifier());

// ── Agent service ─────────────────────────────────────────────────────────────
final agentServiceProvider = Provider<AgentService>((ref) {
  final svc = AgentService(ref);
  // Auto-cancel in-flight stream when the provider is disposed.
  ref.onDispose(svc.cancelStream);
  return svc;
});

class AgentService {
  final Ref _ref;

  // The single in-flight subscription. Cancelled before every new send.
  StreamSubscription<String>? _sub;
  // Guards against starting a new send while one is being set up.
  bool _busy = false;

  AgentService(this._ref);

  // ── Cancel any running stream ─────────────────────────────────────────────
  void cancelStream() {
    _sub?.cancel();
    _sub = null;
    _busy = false;
    // Reset UI state so the sphere goes idle, not stuck "responding".
    try {
      _ref.read(agentStateProvider.notifier).setIdle();
      _ref.read(streamingTextProvider.notifier).clear();
    } catch (_) {
      // Provider may already be disposed — safe to ignore.
    }
  }

  // ── Send a message ────────────────────────────────────────────────────────
  Future<void> send({
    required String userMessage,
    required AppDatabase db,
    bool onboarding = false,
  }) async {
    // Kill any previous in-flight stream before starting a new one.
    await _sub?.cancel();
    _sub = null;

    if (_busy) return; // Debounce rapid double-taps.
    _busy = true;

    final agentN = _ref.read(agentStateProvider.notifier);
    final convN  = _ref.read(conversationProvider.notifier);
    final streamN = _ref.read(streamingTextProvider.notifier);

    // Record the user turn.
    convN.addMessage(AgentMessage(
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    ));

    agentN.setProcessing();

    // Build system prompt (may do DB reads — keep outside the stream).
    final String systemPrompt;
    try {
      systemPrompt = onboarding
          ? ContextBuilder.instance.onboardingSystemPrompt()
          : await ContextBuilder.instance.build(db);
    } catch (_) {
      agentN.setOffline();
      _busy = false;
      return;
    }

    // Limit history to last 8 turns to keep the prompt size manageable.
    final history = _ref
        .read(conversationProvider)
        .where((m) => !(m.role == 'user' && m.content == userMessage))
        .takeLast(8)
        .map((m) => m.toHistoryMap())
        .toList();

    agentN.setResponding();
    streamN.clear();

    final buf = StringBuffer();
    final completer = Completer<void>();

    _sub = OllamaService.instance
        .generate(
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          history: history,
        )
        .listen(
          (token) {
            buf.write(token);
            streamN.append(token);
          },
          onDone: () {
            _sub = null;
            _busy = false;
            final response = buf.toString().trim();
            if (response.isNotEmpty) {
              convN.addMessage(AgentMessage(
                role: 'assistant',
                content: response,
                timestamp: DateTime.now(),
              ));
            }
            streamN.clear();
            agentN.setIdle();
            if (!completer.isCompleted) completer.complete();
          },
          onError: (_) {
            _sub = null;
            _busy = false;
            streamN.clear();
            agentN.setOffline();
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );

    _busy = false; // Allow new sends while this one streams.
    await completer.future;
  }

  /// Background trigger — no UI state, no history, just a one-shot response.
  Future<String> backgroundTrigger({
    required String prompt,
    required AppDatabase db,
  }) async {
    final systemPrompt = await ContextBuilder.instance.build(db);
    return OllamaService.instance.ask(
      systemPrompt: systemPrompt,
      userMessage: prompt,
    );
  }
}

// ── Extension ─────────────────────────────────────────────────────────────────
extension _TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final list = toList();
    if (list.length <= n) return list;
    return list.sublist(list.length - n);
  }
}
