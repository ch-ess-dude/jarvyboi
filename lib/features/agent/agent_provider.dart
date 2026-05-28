// agent_provider.dart — Riverpod state for the Agent Panel.

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

  /// Updates the last assistant message in-place (for streaming).
  void appendToLast(String token) {
    if (state.isEmpty || state.last.role != 'assistant') {
      state = [
        ...state,
        AgentMessage(
          role: 'assistant',
          content: token,
          timestamp: DateTime.now(),
        ),
      ];
    } else {
      final updated = state.last;
      final newMsg = AgentMessage(
        role: updated.role,
        content: updated.content + token,
        timestamp: updated.timestamp,
      );
      state = [...state.sublist(0, state.length - 1), newMsg];
    }
  }

  void clear() => state = [];
}

// ── Streaming response notifier ───────────────────────────────────────────────
class StreamingTextNotifier extends StateNotifier<String> {
  StreamingTextNotifier() : super('');

  void clear() => state = '';
  void append(String token) => state = state + token;
  void set(String text) => state = text;
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

// ── Agent service (singleton-backed) ─────────────────────────────────────────
final agentServiceProvider = Provider<AgentService>((ref) {
  return AgentService(ref);
});

class AgentService {
  final Ref _ref;
  AgentService(this._ref);

  Future<void> send({
    required String userMessage,
    required AppDatabase db,
    bool onboarding = false,
  }) async {
    final agentN = _ref.read(agentStateProvider.notifier);
    final convN = _ref.read(conversationProvider.notifier);
    final streamN = _ref.read(streamingTextProvider.notifier);

    // Add user message to history.
    convN.addMessage(AgentMessage(
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    ));

    // Build system prompt.
    agentN.setProcessing();
    final systemPrompt = onboarding
        ? ContextBuilder.instance.onboardingSystemPrompt()
        : await ContextBuilder.instance.build(db);

    // Assemble history (last 10 turns to stay within context window).
    final history = _ref
        .read(conversationProvider)
        .where((m) => m.role != 'user' || m.content != userMessage)
        .takeLast(10)
        .map((m) => m.toHistoryMap())
        .toList();

    agentN.setResponding();
    streamN.clear();

    final buf = StringBuffer();
    try {
      await for (final token in OllamaService.instance.generate(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        history: history,
      )) {
        buf.write(token);
        streamN.append(token);
      }
    } catch (_) {
      agentN.setOffline();
      return;
    }

    final fullResponse = buf.toString().trim();
    convN.addMessage(AgentMessage(
      role: 'assistant',
      content: fullResponse,
      timestamp: DateTime.now(),
    ));
    streamN.clear();
    agentN.setIdle();
  }

  /// Trigger a background agent call (daily briefing, interest logged, etc.)
  /// Returns the response string without touching the conversation history.
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

// ── Extension for takeLast ────────────────────────────────────────────────────
extension _TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final list = toList();
    if (list.length <= n) return list;
    return list.sublist(list.length - n);
  }
}
