// model_config.dart — Model-agnostic inference configuration.
// Primary: Ollama (local). Fallback: Claude Haiku or any OpenAI-compatible endpoint.

enum InferenceBackend { ollama, claude, openAiCompat }

class ModelConfig {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final ModelConfig instance = ModelConfig._();
  ModelConfig._();

  // ── Active backend ────────────────────────────────────────────────────────
  InferenceBackend backend = InferenceBackend.ollama;

  // ── Ollama (primary) ──────────────────────────────────────────────────────
  String ollamaBaseUrl = 'http://localhost:11434';
  String ollamaModel = 'mistral';

  // ── Claude API (fallback) ─────────────────────────────────────────────────
  String claudeBaseUrl = 'https://api.anthropic.com/v1';
  String claudeModel = 'claude-haiku-4-5';
  String claudeApiKey = ''; // set via env or settings

  // ── OpenAI-compatible endpoint (secondary fallback) ───────────────────────
  String openAiBaseUrl = 'https://api.openai.com/v1';
  String openAiModel = 'gpt-4o-mini';
  String openAiApiKey = '';

  // ── Inference params ──────────────────────────────────────────────────────
  double temperature = 0.7;
  int maxTokens = 1024;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get activeEndpoint {
    switch (backend) {
      case InferenceBackend.ollama:
        return '$ollamaBaseUrl/api/generate';
      case InferenceBackend.claude:
        return '$claudeBaseUrl/messages';
      case InferenceBackend.openAiCompat:
        return '$openAiBaseUrl/chat/completions';
    }
  }

  String get activeModel {
    switch (backend) {
      case InferenceBackend.ollama:
        return ollamaModel;
      case InferenceBackend.claude:
        return claudeModel;
      case InferenceBackend.openAiCompat:
        return openAiModel;
    }
  }

  String? get activeApiKey {
    switch (backend) {
      case InferenceBackend.ollama:
        return null; // local, no key needed
      case InferenceBackend.claude:
        return claudeApiKey.isEmpty ? null : claudeApiKey;
      case InferenceBackend.openAiCompat:
        return openAiApiKey.isEmpty ? null : openAiApiKey;
    }
  }

  /// Switch to next available backend (used on connection failure).
  void fallback() {
    switch (backend) {
      case InferenceBackend.ollama:
        backend = InferenceBackend.claude;
        break;
      case InferenceBackend.claude:
        backend = InferenceBackend.openAiCompat;
        break;
      case InferenceBackend.openAiCompat:
        break; // already at last fallback
    }
  }

  /// Reset to primary (Ollama).
  void resetToOllama() {
    backend = InferenceBackend.ollama;
  }
}
