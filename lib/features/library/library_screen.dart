// library_screen.dart — register: literary
// Warm paper dark, burgundy accent. Playfair Display + DM Sans.
// A personal commonplace book. Annotated, not aggregated.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/jarvy_theme.dart';
import 'library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchCtrl = TextEditingController();
  bool _searchActive = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = JarvyTheme.of(context);
    final pinsAsync = ref.watch(pinsProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, t),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                JarvySpacing.xl, 0,
                JarvySpacing.xl,
                MediaQuery.paddingOf(context).bottom + 80,
              ),
              sliver: pinsAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: JarvySpacing.xl),
                    child: Center(
                      child: Text('Loading…',
                          style: t.body.copyWith(color: t.faint)),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(JarvySpacing.lg),
                    child: Text('Could not load library.',
                        style: t.body.copyWith(color: t.muted)),
                  ),
                ),
                data: (pins) => _buildCatalogue(pins, t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JarvyRegister t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          JarvySpacing.xl, JarvySpacing.xxl, JarvySpacing.xl, 0),
      child: Column(
        children: [
          // ── Kicker ────────────────────────────────────────────────────
          Text(
            '· LIBRARY ·',
            style: t.kicker.copyWith(
                color: t.accent,
                letterSpacing: 3,
                fontSize: 9),
          ),
          const SizedBox(height: JarvySpacing.md),

          // ── Frontispiece title ─────────────────────────────────────────
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: t.displayLarge,
              children: [
                const TextSpan(text: 'The Commonplace\n'),
                TextSpan(
                  text: 'of M. Singh',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: t.inkSoft,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'vol. iii · spring · two hundred forty-one entries',
            style: t.bodyEmph.copyWith(color: t.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // ── Ornament ──────────────────────────────────────────────────
          Text('❦',
              style: t.title.copyWith(
                  color: t.accentDim ?? t.accent, fontSize: 16, letterSpacing: 4)),
          const SizedBox(height: JarvySpacing.lg),

          // ── Search bar — minimal, margin-note style ────────────────────
          GestureDetector(
            onTap: () => setState(() => _searchActive = true),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: t.rule, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 13, color: t.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _searchActive
                        ? TextField(
                            controller: _searchCtrl,
                            style: t.title.copyWith(
                                fontSize: 14,
                                fontStyle: FontStyle.italic),
                            cursorColor: t.accent,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'find a thing you saved…',
                              hintStyle: t.title.copyWith(
                                fontSize: 14,
                                color: t.faint,
                                fontStyle: FontStyle.italic,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (q) => ref
                                .read(librarySearchQueryProvider.notifier)
                                .state = q,
                            onSubmitted: (_) =>
                                setState(() => _searchActive = false),
                          )
                        : Text('find a thing you saved…',
                            style: t.title.copyWith(
                              fontSize: 14,
                              color: t.faint,
                              fontStyle: FontStyle.italic,
                            )),
                  ),
                  Text('by date · by kind · by tag',
                      style: t.metadata.copyWith(letterSpacing: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildCatalogue(List<dynamic> pins, JarvyRegister t) {
    // Group into "this week" and "earlier"
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final thisWeek =
        pins.where((p) => (p.createdAt as DateTime).isAfter(weekAgo)).toList();
    final earlier =
        pins.where((p) => !(p.createdAt as DateTime).isAfter(weekAgo)).toList();

    final widgets = <Widget>[];

    if (thisWeek.isNotEmpty) {
      widgets.add(_SectionLabel(label: 'This week', t: t));
      widgets.addAll(thisWeek.map((p) => _CatalogueEntry(pin: p, t: t)));
    }
    if (earlier.isNotEmpty) {
      widgets.add(_SectionLabel(label: 'Earlier', t: t, muted: true));
      widgets.addAll(earlier.map((p) => _CatalogueEntry(pin: p, t: t)));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => widgets[i],
        childCount: widgets.length,
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final JarvyRegister t;
  final bool muted;
  const _SectionLabel(
      {required this.label, required this.t, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: JarvySpacing.lg, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: t.kicker.copyWith(
          color: muted ? t.muted : t.accent,
          letterSpacing: 2.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Catalogue entry ───────────────────────────────────────────────────────

class _CatalogueEntry extends StatelessWidget {
  final dynamic pin;
  final JarvyRegister t;
  const _CatalogueEntry({required this.pin, required this.t});

  List<String> get _tags {
    final raw = (pin.tags as String?) ?? '[]';
    // Simple JSON array parse (no external package needed)
    return raw
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.lg),
      decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Roman numeral index
          if ((pin.numeral as String?) != null)
            Padding(
              padding: const EdgeInsets.only(right: JarvySpacing.md),
              child: Text(
                pin.numeral as String,
                style: t.title.copyWith(
                    color: t.accent,
                    fontStyle: FontStyle.italic,
                    fontSize: 13),
              ),
            ),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kind tag
                Text(
                  (pin.type as String).toUpperCase(),
                  style: t.kicker.copyWith(
                      color: t.accent,
                      letterSpacing: 1.6,
                      fontSize: 9),
                ),
                const SizedBox(height: 4),

                // Title (Playfair Display)
                Text(
                  pin.content as String,
                  style: t.title.copyWith(fontSize: 22, height: 1.18),
                ),

                // Author
                if ((pin.author as String?) != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    pin.author as String,
                    style: t.body.copyWith(
                        color: t.muted,
                        fontStyle: FontStyle.italic,
                        fontSize: 14),
                  ),
                ],

                // Italic note in left-bordered blockquote
                if ((pin.note as String?) != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                            color: t.accentDim ?? t.accent,
                            width: 1.5),
                      ),
                    ),
                    child: Text(
                      '"${pin.note}"',
                      style: t.bodyEmph.copyWith(
                          color: t.inkSoft, height: 1.5, fontSize: 14),
                    ),
                  ),
                ],

                // Tags + returns
                const SizedBox(height: 8),
                Row(
                  children: [
                    ..._tags.map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            tag,
                            style: t.metadata.copyWith(
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.6),
                          ),
                        )),
                    const Spacer(),
                    if ((pin.returnsLabel as String?) != null)
                      Text(
                        (pin.returnsLabel as String).toUpperCase(),
                        style: t.kicker.copyWith(
                            color: t.accent,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
