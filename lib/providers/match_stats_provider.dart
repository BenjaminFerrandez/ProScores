import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/football_repository.dart';
import '../models/match_stats.dart';
import 'match_detail_provider.dart';
import 'repository_providers.dart';

/// Loads team form, squads and head-to-head history for a fixture, on demand.
/// Kept off the match list so we only spend API-Football credits when a user
/// actually opens a match's stats.
final matchStatsProvider =
    FutureProvider.family<MatchStats, int>((ref, fixtureId) async {
  final fixture = await ref.watch(matchDetailProvider(fixtureId).future);
  final repo = ref.watch(footballRepositoryProvider);

  final homeId = await repo.resolveTeamId(fixture.home.lookupName);
  final awayId = await repo.resolveTeamId(fixture.away.lookupName);
  if (homeId == null || awayId == null) {
    throw ApiException(
        'Statistiques indisponibles pour ${fixture.home.name} / ${fixture.away.name}.');
  }

  // Kick all calls off in parallel, then await each.
  final homeResults = repo.recentResults(homeId);
  final awayResults = repo.recentResults(awayId);
  final homeSquad = repo.squad(homeId);
  final awaySquad = repo.squad(awayId);
  final h2h = repo.headToHead(homeId, awayId);
  await Future.wait(
      [homeResults, awayResults, homeSquad, awaySquad, h2h]);

  return MatchStats(
    home: TeamDossier(
      teamId: homeId,
      name: fixture.home.name,
      recentResults: await homeResults,
      squad: await homeSquad,
    ),
    away: TeamDossier(
      teamId: awayId,
      name: fixture.away.name,
      recentResults: await awayResults,
      squad: await awaySquad,
    ),
    headToHead: await h2h,
  );
});
