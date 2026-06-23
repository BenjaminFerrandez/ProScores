import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market.dart';
import '../models/match_fixture.dart';
import '../services/market_builder.dart';
import 'matches_provider.dart';
import 'repository_providers.dart';

/// Loads a fixture and populates its 1X2 market by combining odds + prediction.
final matchDetailProvider =
    FutureProvider.family<MatchFixture, int>((ref, fixtureId) async {
  final fixtures = await ref.watch(upcomingMatchesProvider.future);
  final fixture = fixtures.firstWhere((f) => f.id == fixtureId);

  final football = ref.watch(footballRepositoryProvider);
  final odds = ref.watch(oddsRepositoryProvider);

  final prediction = await football.predictionFor(fixtureId);
  final marketOdds =
      await odds.marketOddsFor(fixture.home.name, fixture.away.name);

  final markets = <Market>[];
  final h2h = marketOdds['1x2'];
  if (h2h != null && h2h.length == 3) {
    markets.add(
        MarketBuilder.build1x2(bookmakerOdds: h2h, prediction: prediction));
  }
  return fixture.copyWith(markets: markets);
});
