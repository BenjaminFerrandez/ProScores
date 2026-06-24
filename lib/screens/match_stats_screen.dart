import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/country_names.dart';
import '../config/theme.dart';
import '../models/match_stats.dart';
import '../providers/match_stats_provider.dart';
import '../widgets/error_retry.dart';

class MatchStatsScreen extends ConsumerWidget {
  const MatchStatsScreen({super.key, required this.fixtureId});
  final int fixtureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(matchStatsProvider(fixtureId));
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.dark,
          title: const Text('Stats & historique')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
            message: 'Statistiques indisponibles.\n$e',
            onRetry: () => ref.invalidate(matchStatsProvider(fixtureId))),
        data: (s) => ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _H2HSection(s.headToHead),
            const SizedBox(height: 8),
            _TeamSection(s.home),
            const SizedBox(height: 8),
            _TeamSection(s.away),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1)),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: child,
      );
}

Color _outcomeColor(String o) => switch (o) {
      'W' => const Color(0xFF5FE3B6),
      'D' => const Color(0xFFE3D65F),
      _ => const Color(0xFFE35F5F),
    };

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge(this.outcome);
  final String outcome;
  @override
  Widget build(BuildContext context) {
    final c = _outcomeColor(outcome);
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(5)),
      child: Text(outcome,
          style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _H2HSection extends StatelessWidget {
  const _H2HSection(this.matches);
  final List<H2HMatch> matches;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Confrontations directes'),
        _Card(
          child: matches.isEmpty
              ? const Text('Aucune confrontation récente.',
                  style: TextStyle(color: AppColors.muted))
              : Column(
                  children: [
                    for (final m in matches)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 64,
                                child: Text(
                                    DateFormat('MMM yyyy', 'fr_FR')
                                        .format(m.date.toLocal()),
                                    style: const TextStyle(
                                        color: AppColors.muted, fontSize: 11))),
                            Expanded(
                                child: Text(frCountry(m.homeName),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                  '${m.homeGoals ?? '-'} - ${m.awayGoals ?? '-'}',
                                  style: tabularNumberStyle(const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.light))),
                            ),
                            Expanded(
                                child: Text(frCountry(m.awayName),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection(this.team);
  final TeamDossier team;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(team.name),
        if (team.recentResults.isNotEmpty)
          _Card(child: _ResultsBlock(team.recentResults)),
        if (team.squad.isNotEmpty) _Card(child: _SquadBlock(team.squad)),
        if (team.recentResults.isEmpty && team.squad.isEmpty)
          const _Card(
            child: Text('Aucune donnée disponible pour cette équipe.',
                style: TextStyle(color: AppColors.muted)),
          ),
      ],
    );
  }
}

class _ResultsBlock extends StatelessWidget {
  const _ResultsBlock(this.results);
  final List<TeamResult> results;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Derniers résultats',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            // form dots, oldest left -> most recent right
            for (final r in results.reversed)
              Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _OutcomeBadge(r.outcome)),
          ],
        ),
        const SizedBox(height: 8),
        for (final r in results)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                    width: 56,
                    child: Text(
                        DateFormat('d MMM', 'fr_FR').format(r.date.toLocal()),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11))),
                SizedBox(
                    width: 26,
                    child: Text(r.isHome ? 'dom.' : 'ext.',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 10))),
                Expanded(
                    child: Text(frCountry(r.opponent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13))),
                Text('${r.goalsFor} - ${r.goalsAgainst}',
                    style: tabularNumberStyle(const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.light))),
                const SizedBox(width: 8),
                _OutcomeBadge(r.outcome),
              ],
            ),
          ),
      ],
    );
  }
}

class _SquadBlock extends StatelessWidget {
  const _SquadBlock(this.squad);
  final List<SquadPlayer> squad;

  static const _order = ['Goalkeeper', 'Defender', 'Midfielder', 'Attacker'];
  static const _labels = {
    'Goalkeeper': 'Gardiens',
    'Defender': 'Défenseurs',
    'Midfielder': 'Milieux',
    'Attacker': 'Attaquants',
  };

  @override
  Widget build(BuildContext context) {
    final byPos = <String, List<SquadPlayer>>{};
    for (final p in squad) {
      byPos.putIfAbsent(p.position ?? 'Autres', () => []).add(p);
    }
    // sort each group by goals desc for a bit of insight
    for (final l in byPos.values) {
      l.sort((a, b) => (b.goals ?? 0).compareTo(a.goals ?? 0));
    }
    final positions = [
      ..._order.where(byPos.containsKey),
      ...byPos.keys.where((k) => !_order.contains(k)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Effectif (${squad.length})',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final pos in positions) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(_labels[pos] ?? pos,
                style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          for (final p in byPos[pos]!)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                      child: Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13))),
                  if ((p.appearances ?? 0) > 0)
                    Text('${p.appearances} m',
                        style: tabularNumberStyle(const TextStyle(
                            color: AppColors.muted, fontSize: 11))),
                  if ((p.goals ?? 0) > 0) ...[
                    const SizedBox(width: 10),
                    Text('${p.goals} ⚽',
                        style: tabularNumberStyle(const TextStyle(
                            color: AppColors.light,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}
