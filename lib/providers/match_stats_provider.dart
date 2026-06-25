import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_stats.dart';
import 'match_detail_provider.dart';
import 'repository_providers.dart';

/// Loads team form, squads and head-to-head history for a fixture, on demand.
/// A single backend call (`/match/stats`) resolves the ids and bundles
/// everything — the server caches each part, so credits are only spent once.
final matchStatsProvider =
    FutureProvider.family<MatchStats, int>((ref, fixtureId) async {
  final fixture = await ref.watch(matchDetailProvider(fixtureId).future);
  final repo = ref.watch(footballRepositoryProvider);

  final s = await repo.matchStats(
      fixture.home.lookupName, fixture.away.lookupName);

  return MatchStats(
    home: TeamDossier(
      teamId: s.homeId,
      name: fixture.home.name,
      recentResults: s.homeResults,
      squad: s.homeSquad,
    ),
    away: TeamDossier(
      teamId: s.awayId,
      name: fixture.away.name,
      recentResults: s.awayResults,
      squad: s.awaySquad,
    ),
    headToHead: s.h2h,
  );
});
