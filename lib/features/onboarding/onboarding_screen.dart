// onboarding_screen.dart — Conversational first-launch onboarding.
// Jarvis greets first, asks 5 questions, parses answers into Drift.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../agent/agent_panel.dart';
import '../agent/agent_provider.dart';
import '../agent/sphere_painter.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Watch conversation for completion tag.
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickOffOnboarding());
  }

  Future<void> _kickOffOnboarding() async {
    final db = ref.read(dbProvider);
    // Jarvis greets first.
    await ref.read(agentServiceProvider).send(
          userMessage: '__init_onboarding__',
          db: db,
          onboarding: true,
        );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentStateProvider);
    final conversation = ref.watch(conversationProvider);

    // Detect [ONBOARDING_COMPLETE] in the last assistant message.
    final lastAssistant = conversation.lastWhere(
      (m) => m.role == 'assistant',
      orElse: () => AgentMessage(
          role: '', content: '', timestamp: DateTime.fromMillisecondsSinceEpoch(0)),
    );
    if (lastAssistant.content.contains('[ONBOARDING_COMPLETE]')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishOnboarding());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D0F),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Sphere
              Center(child: AnimatedSphere(state: agentState, size: 110)),
              const SizedBox(height: 20),
              const Text(
                'Hi, I\'m Jarvis.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Let\'s get you set up.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              // Conversation panel takes remaining space.
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: AgentPanel(isOnboarding: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    if (!mounted) return;
    final db = ref.read(dbProvider);

    // Parse last full conversation for config values.
    final fullText = ref
        .read(conversationProvider)
        .where((m) => m.role == 'assistant')
        .map((m) => m.content)
        .join('\n');

    await _parseAndSaveConfig(fullText, db);
    await db.setConfig('onboarding_complete', 'true');

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  /// Lightweight heuristic parser — extracts config from conversation text.
  Future<void> _parseAndSaveConfig(String text, AppDatabase db) async {
    // Calorie target: look for standalone 4-digit number near "calorie"
    final calRe = RegExp(r'(\d{3,4})\s*(?:kcal|calories|cal)', caseSensitive: false);
    final calMatch = calRe.firstMatch(text);
    if (calMatch != null) {
      await db.setConfig('calorie_target', calMatch.group(1)!);
    } else {
      await db.setConfig('calorie_target', '2000'); // sensible default
    }

    // Macro split: look for P/C/F percentages.
    final macroRe =
        RegExp(r'(\d{1,3})%?\s*[Pp]rotein.*?(\d{1,3})%?\s*[Cc]arb.*?(\d{1,3})%?\s*[Ff]at');
    final macroMatch = macroRe.firstMatch(text);
    if (macroMatch != null) {
      await db.setConfig('macro_protein_pct', macroMatch.group(1)!);
      await db.setConfig('macro_carb_pct', macroMatch.group(2)!);
      await db.setConfig('macro_fat_pct', macroMatch.group(3)!);
    } else if (text.toLowerCase().contains('high protein') ||
        text.toLowerCase().contains('high-protein')) {
      await db.setConfig('macro_protein_pct', '35');
      await db.setConfig('macro_carb_pct', '40');
      await db.setConfig('macro_fat_pct', '25');
    } else if (text.toLowerCase().contains('low carb') ||
        text.toLowerCase().contains('low-carb')) {
      await db.setConfig('macro_protein_pct', '30');
      await db.setConfig('macro_carb_pct', '25');
      await db.setConfig('macro_fat_pct', '45');
    } else {
      // Balanced default.
      await db.setConfig('macro_protein_pct', '30');
      await db.setConfig('macro_carb_pct', '45');
      await db.setConfig('macro_fat_pct', '25');
    }

    // Training days: look for digit near "days"
    final daysRe = RegExp(r'(\d)\s*(?:days?|times?)\s*(?:a|per)?\s*week',
        caseSensitive: false);
    final daysMatch = daysRe.firstMatch(text);
    await db.setConfig(
        'training_days_per_week', daysMatch?.group(1) ?? '3');

    // Training type
    String trainingType = 'mixed';
    if (text.toLowerCase().contains('strength') ||
        text.toLowerCase().contains('weight')) {
      trainingType = 'strength';
    } else if (text.toLowerCase().contains('cardio') ||
        text.toLowerCase().contains('running')) {
      trainingType = 'cardio';
    }
    await db.setConfig('training_type', trainingType);
  }
}
