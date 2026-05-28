// ollama_service.dart — Streaming inference client.
// Handles Ollama (primary), Claude Haiku (fallback), OpenAI-compat (2nd fallback).
// Emits token-by-token via Stream<String>.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model_config.dart';

class OllamaService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final OllamaService instance = OllamaService._();
  OllamaService._();

  final _config = ModelConfig.instance;

  // ── Health check ──────────────────────────────────────────────────────────
  /// Returns true if Ollama responds at localhost:11434.
  Future<bool> isOllamaAvailable() async {
    try {
      final res = await http
          .get(Uri.parse('${_config.ollamaBaseUrl}/api/tags'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Primary streaming call ────────────────────────────────────────────────
  /// Streams inference tokens. Auto-falls back to Claude → OpenAI on failure.
  Stream<String> generate({
    required String systemPrompt,
    required String userMessage,
    List<Map<String, String>> history = const [],
  }) async* {
    // Always try Ollama first if available.
    if (_config.backend != InferenceBackend.ollama) {
      if (await isOllamaAvailable()) {
        _config.resetToOllama();
      }
    }

    try {
      switch (_config.backend) {
        case InferenceBackend.ollama:
          yield* _ollamaStream(
              systemPrompt: systemPrompt,
              userMessage: userMessage,
              history: history);
          break;
        case InferenceBackend.claude:
          yield* _claudeStream(
              systemPrompt: systemPrompt,
              userMessage: userMessage,
              history: history);
          break;
        case InferenceBackend.openAiCompat:
          yield* _openAiStream(
              systemPrompt: systemPrompt,
              userMessage: userMessage,
              history: history);
          break;
      }
    } catch (e) {
      _config.fallback();
      // One retry on the new backend.
      try {
        switch (_config.backend) {
          case InferenceBackend.ollama:
            yield* _ollamaStream(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                history: history);
            break;
          case InferenceBackend.claude:
            yield* _claudeStream(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                history: history);
            break;
          case InferenceBackend.openAiCompat:
            yield* _openAiStream(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                history: history);
            break;
        }
      } catch (_) {
        yield '';
      }
    }
  }

  // ── Ollama streaming ──────────────────────────────────────────────────────
  Stream<String> _ollamaStream({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async* {
    // Build a single prompt string with system context + conversation turns.
    final buffer = StringBuffer();
    buffer.writeln('[SYSTEM]');
    buffer.writeln(systemPrompt);
    buffer.writeln('[/SYSTEM]');
    for (final msg in history) {
      final role = msg['role'] == 'assistant' ? 'JARVIS' : 'USER';
      buffer.writeln('\n[$role]: ${msg['content']}');
    }
    buffer.writeln('\n[USER]: $userMessage');
    buffer.writeln('[JARVIS]:');

    final body = jsonEncode({
      'model': _config.ollamaModel,
      'prompt': buffer.toString(),
      'stream': true,
      'options': {
        'temperature': _config.temperature,
        'num_predict': _config.maxTokens,
      },
    });

    final request = http.Request('POST', Uri.parse(_config.activeEndpoint));
    request.headers['Content-Type'] = 'application/json';
    request.body = body;

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        client.close();
        throw Exception('Ollama ${response.statusCode}');
      }

      await for (final chunk
          in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;
        try {
          final json = jsonDecode(chunk) as Map<String, dynamic>;
          final token = json['response'] as String? ?? '';
          if (token.isNotEmpty) yield token;
          if (json['done'] == true) break;
        } catch (_) {
          continue;
        }
      }
    } finally {
      client.close();
    }
  }

  // ── Claude (Anthropic Messages API) streaming ─────────────────────────────
  Stream<String> _claudeStream({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async* {
    final apiKey = _config.claudeApiKey;
    if (apiKey.isEmpty) {
      throw Exception('Claude API key not configured');
    }

    final messages = <Map<String, dynamic>>[
      ...history.map((m) => {'role': m['role'], 'content': m['content']}),
      {'role': 'user', 'content': userMessage},
    ];

    final body = jsonEncode({
      'model': _config.claudeModel,
      'max_tokens': _config.maxTokens,
      'system': systemPrompt,
      'messages': messages,
      'stream': true,
    });

    final request =
        http.Request('POST', Uri.parse('${_config.claudeBaseUrl}/messages'));
    request.headers['Content-Type'] = 'application/json';
    request.headers['x-api-key'] = apiKey;
    request.headers['anthropic-version'] = '2023-06-01';
    request.body = body;

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        client.close();
        throw Exception('Claude ${response.statusCode}');
      }

      await for (final line
          in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (json['type'] == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            final text = delta?['text'] as String? ?? '';
            if (text.isNotEmpty) yield text;
          }
        } catch (_) {
          continue;
        }
      }
    } finally {
      client.close();
    }
  }

  // ── OpenAI-compatible streaming ───────────────────────────────────────────
  Stream<String> _openAiStream({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async* {
    final apiKey = _config.openAiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {'role': m['role'], 'content': m['content']}),
      {'role': 'user', 'content': userMessage},
    ];

    final body = jsonEncode({
      'model': _config.openAiModel,
      'messages': messages,
      'max_tokens': _config.maxTokens,
      'temperature': _config.temperature,
      'stream': true,
    });

    final request = http.Request(
        'POST', Uri.parse('${_config.openAiBaseUrl}/chat/completions'));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.body = body;

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        client.close();
        throw Exception('OpenAI ${response.statusCode}');
      }

      await for (final line
          in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;
          final delta =
              (choices.first as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;
          final token = delta?['content'] as String? ?? '';
          if (token.isNotEmpty) yield token;
        } catch (_) {
          continue;
        }
      }
    } finally {
      client.close();
    }
  }

  // ── Non-streaming convenience (for triggers / background calls) ───────────
  Future<String> ask({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final buf = StringBuffer();
    await for (final token
        in generate(systemPrompt: systemPrompt, userMessage: userMessage)) {
      buf.write(token);
    }
    return buf.toString().trim();
  }
}
