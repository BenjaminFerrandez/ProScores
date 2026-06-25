import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import '../providers/matches_provider.dart';
import '../widgets/error_retry.dart';
import 'account_screen.dart';
import 'create_prono_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(worldCupFixturesProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: RichText(
          text: TextSpan(children: [
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
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Mon compte',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          ref.invalidate(worldCupFixturesProvider);
          await ref.read(worldCupFixturesProvider.future);
        },
        child: matches.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
              message: 'Impossible de charger les matchs.\n$e',
              onRetry: () => ref.invalidate(worldCupFixturesProvider)),
          data: (list) => _MatchList(list),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CreatePronoScreen())),
            child: const Text('Crée ton prono !',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList(this.matches);
  final List<MatchFixture> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 120),
            child: Center(
                child: Text('Aucun match à venir.',
                    style: TextStyle(color: AppColors.muted))),
          ),
        ],
      );
    }
    // group by calendar day
    final byDay = <String, List<MatchFixture>>{};
    for (final m in matches) {
      final key = DateFormat('EEEE d MMM', 'fr_FR').format(m.kickoff.toLocal());
      byDay.putIfAbsent(key, () => []).add(m);
    }
    final days = byDay.keys.toList();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        final games = byDay[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(day.toUpperCase(),
                  style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1)),
            ),
            ...games.map((m) => _MatchRow(m)),
          ],
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow(this.match);
  final MatchFixture match;
  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(match.kickoff.toLocal());
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MatchDetailScreen(fixtureId: match.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            SizedBox(
                width: 44,
                child: Text(time,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.home.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(match.away.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            _Favorite(match),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Shows the most probable 1X2 outcome (percentage + short label).
class _Favorite extends StatelessWidget {
  const _Favorite(this.match);
  final MatchFixture match;
  @override
  Widget build(BuildContext context) {
    if (match.markets.isEmpty) return const SizedBox.shrink();
    final selections = match.markets.first.selections;
    var bestIndex = 0;
    for (var i = 1; i < selections.length; i++) {
      if (selections[i].adjustedProbability >
          selections[bestIndex].adjustedProbability) {
        bestIndex = i;
      }
    }
    final best = selections[bestIndex];
    final label = switch (bestIndex) {
      0 => match.home.name,
      1 => 'Nul',
      _ => match.away.name,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${(best.adjustedProbability * 100).round()}%',
            style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        SizedBox(
          width: 70,
          child: Text(label,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.muted, fontSize: 9)),
        ),
      ],
    );
  }
}
