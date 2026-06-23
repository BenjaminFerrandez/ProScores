import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market.dart';
import '../models/match_fixture.dart';
import '../models/team.dart';
import '../services/market_builder.dart';
import 'repository_providers.dart';

/// Derives a stable positive int id from The Odds API hex event id.
int stableFixtureId(String hexId) =>
    int.parse(hexId.substring(0, 8), radix: 16);

/// Upcoming World Cup fixtures with their 1X2 market, sourced entirely from
/// The Odds API (fixtures + odds in one call). Probabilities are the implied
/// (margin-removed) bookmaker probabilities.
final worldCupFixturesProvider =
    FutureProvider<List<MatchFixture>>((ref) async {
  final odds = ref.watch(oddsRepositoryProvider);
  final events = await odds.fetchWorldCupEvents();

  final fixtures = <MatchFixture>[];
  for (final e in events) {
    final markets = <Market>[];
    if (e.h2h != null && e.h2h!.length == 3) {
      markets.add(MarketBuilder.build1x2(bookmakerOdds: e.h2h!));
    }
    fixtures.add(MatchFixture(
      id: stableFixtureId(e.id),
      competition: 'Coupe du Monde',
      kickoff: e.commenceTime,
      home: Team(id: 0, name: e.homeTeam),
      away: Team(id: 0, name: e.awayTeam),
      markets: markets,
    ));
  }
  fixtures.sort((a, b) => a.kickoff.compareTo(b.kickoff));
  return fixtures;
});
