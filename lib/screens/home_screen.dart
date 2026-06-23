import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import '../providers/matches_provider.dart';
import '../widgets/error_retry.dart';
import 'create_prono_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(upcomingMatchesProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(
                text: 'Prono',
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
      ),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
            message: 'Impossible de charger les matchs.\n$e',
            onRetry: () => ref.invalidate(upcomingMatchesProvider)),
        data: (list) => _MatchList(list),
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
      return const Center(
          child: Text('Aucun match à venir.',
              style: TextStyle(color: AppColors.muted)));
    }
    // group by calendar day
    final byDay = <String, List<MatchFixture>>{};
    for (final m in matches) {
      final key = DateFormat('EEEE d MMM', 'fr_FR').format(m.kickoff.toLocal());
      byDay.putIfAbsent(key, () => []).add(m);
    }
    final days = byDay.keys.toList();
    return ListView.builder(
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
                  style: const TextStyle(
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
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
