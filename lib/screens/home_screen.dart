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
        centerTitle: true,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Center(
            child: SquareIconButton(
                icon: Icons.sports_soccer, onPressed: null),
          ),
        ),
        title: const AppLogo(height: 34),
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

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.matches, required this.onOpenMatch});
  final List<MatchFixture> matches;
  final void Function(BuildContext, MatchFixture) onOpenMatch;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
          child: Text('Aucun match à venir.',
              style: TextStyle(color: AppColors.muted)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        MatchHeroCarousel(
          matches: matches,
          onTapMatch: (m) => onOpenMatch(context, m),
        ),
        const SizedBox(height: 18),
        const Text('MATCHS À VENIR',
            style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        for (var i = 0; i < matches.length; i++) ...[
          MatchRow(
              match: matches[i],
              onTap: () => onOpenMatch(context, matches[i])),
          // Insert the ad slot after the second match, like the design.
          if (i == 1) ...[
            const AdPlaceholder(),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}
