// build_screen.dart — register: ambition
// True dark, white-gold accent. Playfair Display + Geist.
// Projects list, status-weighted typography. Manifesto that tracks itself.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/jarvy_theme.dart';
import 'build_provider.dart';

class BuildScreen extends ConsumerWidget {
  const BuildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = JarvyTheme.of(context);
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                JarvySpacing.lg, JarvySpacing.md,
                JarvySpacing.lg, 0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        projectsAsync.maybeWhen(
                          data: (p) =>
                              'AMBITION · ${p.length} PROJECTS',
                          orElse: () => 'AMBITION',
                        ),
                        style: t.kicker.copyWith(
                            color: t.accentDim ?? t.accent),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: new project sheet
                        },
                        child: Text('+ NEW',
                            style: t.kicker.copyWith(
                                color: t.muted, letterSpacing: 1.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: JarvySpacing.lg),

                  // ── Manifesto sub-title ────────────────────────────────
                  Text(
                    'What I am becoming —',
                    style: t.title.copyWith(
                        fontStyle: FontStyle.italic,
                        color: t.accent,
                        fontSize: 13),
                  ),

                  const SizedBox(height: JarvySpacing.sm),

                  // ── Projects ───────────────────────────────────────────
                  projectsAsync.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: JarvySpacing.xl),
                      child: Text('Loading…',
                          style:
                              t.body.copyWith(color: t.faint)),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: JarvySpacing.xl),
                      child: Text('Could not load projects.',
                          style: t.body.copyWith(color: t.muted)),
                    ),
                    data: (projects) => projects.isEmpty
                        ? _EmptyProjects(t: t)
                        : Column(
                            children: projects
                                .map((p) => _ProjectCard(
                                    project: p, t: t))
                                .toList(),
                          ),
                  ),

                  SizedBox(
                      height:
                          MediaQuery.paddingOf(context).bottom + 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project card ──────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final dynamic project;
  final JarvyRegister t;
  const _ProjectCard({required this.project, required this.t});

  @override
  Widget build(BuildContext context) {
    final status = project.status as String;
    final isNow = status == 'now';
    final isStalled = status == 'stalled';

    final progressColor = isStalled
        ? (t.destructive ?? oklch(.58, .13, 25))
        : t.accent;
    final kickerColor = isNow ? t.accent : t.muted;
    final pct = (project.progressPct as int).clamp(0, 100);

    final titleSize = isNow ? 36.0 : 24.0;
    final titleWeight = isNow ? FontWeight.w500 : FontWeight.w400;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.lg),
      decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Kicker row ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _kickerLabel(status),
                style: t.kicker.copyWith(
                    color: kickerColor, letterSpacing: 2.4),
              ),
              if ((project.since as String?) != null)
                Text(
                  project.since as String,
                  style: t.metadata,
                ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Project name (Playfair Display) ───────────────────────
          RichText(
            text: TextSpan(
              style: t.displayLarge.copyWith(
                fontSize: titleSize,
                fontWeight: titleWeight,
                letterSpacing: -0.6,
                height: 1.05,
              ),
              children: [
                TextSpan(text: project.name as String),
                if ((project.italicTail as String?) != null) ...[
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: project.italicTail as String,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: t.accent,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Next step quote ───────────────────────────────────────
          if ((project.nextStep as String?) != null) ...[
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(
                        color: t.accentDim ?? t.accent,
                        width: 1.5)),
              ),
              child: Text(
                project.nextStep as String,
                style: t.title.copyWith(
                  fontSize: 14,
                  color: t.inkSoft,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Progress bar ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 2, color: t.rule),
                    FractionallySizedBox(
                      widthFactor: pct / 100.0,
                      child: Container(
                          height: 2, color: progressColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('$pct%',
                  style: t.metadata.copyWith(letterSpacing: 0.4)),
              if ((project.mood as String?) != null) ...[
                const SizedBox(width: 8),
                Text(
                  (project.mood as String).toUpperCase(),
                  style: t.kicker.copyWith(
                    color: isStalled
                        ? (t.destructive ?? oklch(.58, .13, 25))
                        : t.accent,
                    fontSize: 9,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _kickerLabel(String status) {
    switch (status) {
      case 'now':
        return 'NOW · TENT-POLE';
      case 'active':
        return 'ACTIVE';
      case 'stalled':
        return 'STALLED';
      case 'quiet':
        return 'LONG-RUNNING';
      default:
        return status.toUpperCase();
    }
  }
}

class _EmptyProjects extends StatelessWidget {
  final JarvyRegister t;
  const _EmptyProjects({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.xxl),
      child: Center(
        child: Text(
          'No active projects.\nStart something.',
          style: t.title.copyWith(
              color: t.faint, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
