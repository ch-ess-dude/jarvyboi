// mcp_service.dart — MCP (Model Context Protocol) client.
// Talks to the Node.js MCP service running on localhost:3001.
// Also launches the Node service if it isn't running.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class McpService {
  static final McpService instance = McpService._();
  McpService._();

  static const _baseUrl = 'http://localhost:3001';
  static const _timeout = Duration(seconds: 5);

  bool _launched = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  /// Ensure the MCP server is running. No-ops if already up.
  Future<void> ensureRunning() async {
    if (await _isUp()) return;
    if (_launched) return; // already tried launching
    await _launch();
  }

  Future<bool> _isUp() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _launch() async {
    _launched = true;
    try {
      // Resolve the mcp/ directory relative to the executable.
      // In dev this is <project_root>/mcp/index.js.
      final projectRoot = Directory.current.path;
      final mcpDir = '$projectRoot/mcp';
      if (!Directory(mcpDir).existsSync()) return;

      await Process.start(
        'node',
        ['index.js'],
        workingDirectory: mcpDir,
        mode: ProcessStartMode.detached,
      );

      // Give Node a moment to bind.
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (_) {
      // Node not installed or mcp/ dir missing — degrade gracefully.
    }
  }

  // ── Calendar tools ────────────────────────────────────────────────────────
  /// Fetch today's calendar events.
  Future<List<Map<String, dynamic>>> todayEvents() async {
    return _get('/calendar/today');
  }

  /// Fetch events for a date range (ISO strings).
  Future<List<Map<String, dynamic>>> eventsInRange({
    required String start,
    required String end,
  }) async {
    return _get('/calendar/range?start=$start&end=$end');
  }

  /// Create a calendar event.
  Future<bool> createEvent({
    required String title,
    required String startIso,
    required String endIso,
    String? notes,
    String? calendarName,
  }) async {
    return _post('/calendar/create', {
      'title': title,
      'start': startIso,
      'end': endIso,
      if (notes != null) 'notes': notes,
      if (calendarName != null) 'calendar': calendarName,
    });
  }

  // ── Reminders tools ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> pendingReminders() async {
    return _get('/reminders/pending');
  }

  Future<bool> createReminder({
    required String title,
    String? dueDateIso,
    String? listName,
  }) async {
    return _post('/reminders/create', {
      'title': title,
      if (dueDateIso != null) 'dueDate': dueDateIso,
      if (listName != null) 'list': listName,
    });
  }

  // ── Generic helpers ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl$path'))
          .timeout(_timeout);
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Tool dispatcher ───────────────────────────────────────────────────────
  /// Called by the agent when the LLM emits a tool-call JSON blob.
  /// Returns the tool result as a string.
  Future<String> dispatch(String toolName, Map<String, dynamic> args) async {
    switch (toolName) {
      case 'calendar_today':
        final events = await todayEvents();
        if (events.isEmpty) return 'No events today.';
        return events.map((e) => '${e["time"]} — ${e["title"]}').join('\n');

      case 'calendar_create':
        final ok = await createEvent(
          title: args['title'] as String,
          startIso: args['start'] as String,
          endIso: args['end'] as String,
          notes: args['notes'] as String?,
          calendarName: args['calendar'] as String?,
        );
        return ok ? 'Event created.' : 'Failed to create event.';

      case 'reminders_pending':
        final items = await pendingReminders();
        if (items.isEmpty) return 'No pending reminders.';
        return items.map((r) => '- ${r["title"]}').join('\n');

      case 'reminder_create':
        final ok = await createReminder(
          title: args['title'] as String,
          dueDateIso: args['dueDate'] as String?,
          listName: args['list'] as String?,
        );
        return ok ? 'Reminder created.' : 'Failed to create reminder.';

      default:
        return 'Unknown tool: $toolName';
    }
  }
}
