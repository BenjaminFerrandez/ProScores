import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import '../providers/matches_provider.dart';
import '../widgets/ad_placeholder.dart';
import '../widgets/app_logo.dart';
import '../widgets/error_retry.dart';
import '../widgets/match_hero_carousel.dart';
import '../widgets/match_row.dart';
import '../widgets/wobble_button.dart';
import 'create_prono_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openMatch(BuildContext context, MatchFixture m) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MatchDetailScreen(fixtureId: m.id)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(worldCupFixturesProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(
                text: 'ProScores',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.light)),
            TextSpan(
                text: '.',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.teal)),
          ]),
        ),
        actions: const [SizedBox(width: 64)],
      ),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
            message: 'Impossible de charger les matchs.\n$e',
            onRetry: () => ref.invalidate(worldCupFixturesProvider)),
        data: (list) => _HomeBody(matches: list, onOpenMatch: _openMatch),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: WobbleButton(
          label: 'Crée ton prono !',
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePronoScreen())),
        ),
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.matches, required this.onOpenMatch});
  final List<MatchFixture> matches;
  final void Function(BuildContext, MatchFixture) onOpenMatch;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  static const _pageSize = 6;
  final _controller = ScrollController();
  int _visible = 6;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ordered list of below-the-carousel widgets: match rows with the ad slot
  /// inserted after the second match.
  List<Widget> _entries() {
    final entries = <Widget>[];
    for (var i = 0; i < widget.matches.length; i++) {
      final m = widget.matches[i];
      entries.add(MatchRow(match: m, onTap: () => widget.onOpenMatch(context, m)));
      if (i == 1) {
        entries.add(const Padding(
            padding: EdgeInsets.only(bottom: 18), child: AdPlaceholder()));
      }
    }
    return entries;
  }

  void _onScroll() {
    final total = _entries().length;
    if (!_loadingMore &&
        _visible < total &&
        _controller.position.pixels >=
            _controller.position.maxScrollExtent - 400) {
      _loadMore(total);
    }
  }

  Future<void> _loadMore(int total) async {
    setState(() => _loadingMore = true);
    // Small delay so the incremental "loading more" is perceptible.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _visible = (_visible + _pageSize).clamp(0, total);
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) {
      return const Center(
          child: Text('Aucun match à venir.',
              style: TextStyle(color: AppColors.muted)));
    }
    final entries = _entries();
    final shown = _visible.clamp(0, entries.length);
    final hasMore = shown < entries.length;

    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 1 + shown + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MatchHeroCarousel(
                matches: widget.matches,
                onTapMatch: (m) => widget.onOpenMatch(context, m),
              ),
              const SizedBox(height: 18),
              const Text('MATCHS À VENIR',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
            ],
          );
        }
        final entryIndex = index - 1;
        if (entryIndex < shown) return entries[entryIndex];
        // Trailing loader while revealing more.
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
