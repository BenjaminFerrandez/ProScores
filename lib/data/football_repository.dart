import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/match_stats.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

/// Everything the stats screen needs, fetched in a single backend call.
typedef MatchStatsBundle = ({
  int homeId,
  int awayId,
  List<TeamResult> homeResults,
  List<SquadPlayer> homeSquad,
  List<TeamResult> awayResults,
  List<SquadPlayer> awaySquad,
  List<H2HMatch> h2h,
});

abstract class FootballRepository {
  /// Team ids + form + squads + h2h for a fixture, in ONE backend call.
  Future<MatchStatsBundle> matchStats(String homeName, String awayName);

  /// Crest/logo URL of a (national) team by name, or null.
  Future<String?> nationalTeamLogo(String teamName);
}

class HttpFootballRepository implements FootballRepository {
  HttpFootballRepository(this.client);
  final http.Client client;

  // All calls go through our backend proxy (which holds the key and caches).
  static const _base = '$kServerBaseUrl/football';

  @override
  Future<String?> nationalTeamLogo(String teamName) async {
    final uri = Uri.parse(
        '$_base/teams/search?name=${Uri.encodeQueryComponent(teamName)}');
    final res = await client.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['response'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    if (list.isEmpty) return null;
    // Prefer the national team; fall back to the first result.
    final match = list.firstWhere(
      (t) => (t['team'] as Map<String, dynamic>)['national'] == true,
      orElse: () => list.first,
    );
    return (match['team'] as Map<String, dynamic>)['logo'] as String?;
  }

  static const _finished = {'FT', 'AET', 'PEN'};

  // --- Parsing helpers ------------------------------------------------------

  static List<TeamResult> _parseResults(List<dynamic> response, int teamId) {
    final results = <TeamResult>[];
    for (final f in response.cast<Map<String, dynamic>>()) {
      final fixture = f['fixture'] as Map<String, dynamic>;
      final short =
          (fixture['status'] as Map<String, dynamic>)['short'] as String?;
      if (!_finished.contains(short)) continue;
      final teams = f['teams'] as Map<String, dynamic>;
      final home = teams['home'] as Map<String, dynamic>;
      final away = teams['away'] as Map<String, dynamic>;
      final goals = f['goals'] as Map<String, dynamic>;
      final isHome = home['id'] == teamId;
      final gh = (goals['home'] as num?)?.toInt() ?? 0;
      final ga = (goals['away'] as num?)?.toInt() ?? 0;
      results.add(TeamResult(
        date: DateTime.parse(fixture['date'] as String),
        opponent: (isHome ? away : home)['name'] as String,
        isHome: isHome,
        goalsFor: isHome ? gh : ga,
        goalsAgainst: isHome ? ga : gh,
      ));
    }
    results.sort((a, b) => b.date.compareTo(a.date));
    return results.take(kRecentResultsCount).toList();
  }

  static List<SquadPlayer> _parseSquadPage(List<dynamic> response) {
    final players = <SquadPlayer>[];
    for (final p in response.cast<Map<String, dynamic>>()) {
      final player = p['player'] as Map<String, dynamic>;
      final stats =
          (p['statistics'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      String? position;
      var apps = 0;
      var goals = 0;
      for (final s in stats) {
        final games = s['games'] as Map<String, dynamic>?;
        position ??= games?['position'] as String?;
        apps += (games?['appearences'] as num?)?.toInt() ?? 0;
        goals += ((s['goals'] as Map<String, dynamic>?)?['total'] as num?)
                ?.toInt() ??
            0;
      }
      players.add(SquadPlayer(
        name: player['name'] as String? ?? '—',
        position: position,
        appearances: apps,
        goals: goals,
      ));
    }
    return players;
  }

  static List<H2HMatch> _parseH2h(List<dynamic> response) {
    final matches = response.cast<Map<String, dynamic>>().map((f) {
      final fixture = f['fixture'] as Map<String, dynamic>;
      final teams = f['teams'] as Map<String, dynamic>;
      final goals = f['goals'] as Map<String, dynamic>;
      return H2HMatch(
        date: DateTime.parse(fixture['date'] as String),
        homeName: (teams['home'] as Map<String, dynamic>)['name'] as String,
        awayName: (teams['away'] as Map<String, dynamic>)['name'] as String,
        homeGoals: (goals['home'] as num?)?.toInt(),
        awayGoals: (goals['away'] as num?)?.toInt(),
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return matches.take(kH2hCount).toList();
  }

  // --- Public API ----------------------------------------------------------

  @override
  Future<MatchStatsBundle> matchStats(String homeName, String awayName) async {
    final uri = Uri.parse('$kServerBaseUrl/match/stats'
        '?home=${Uri.encodeQueryComponent(homeName)}'
        '&away=${Uri.encodeQueryComponent(awayName)}'
        '&season=$kStatsSeason');
    final res = await client.get(uri);
    if (res.statusCode != 200) {
      throw ApiException('match stats HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final home = data['home'] as Map<String, dynamic>;
    final away = data['away'] as Map<String, dynamic>;
    final homeId = (data['homeId'] as num).toInt();
    final awayId = (data['awayId'] as num).toInt();

    List<SquadPlayer> squadOf(Map<String, dynamic> side) => [
          for (final page
              in (side['players'] as List).cast<Map<String, dynamic>>())
            ..._parseSquadPage(page['response'] as List),
        ];
    List<dynamic> fixturesOf(Map<String, dynamic> side) =>
        (side['fixtures'] as Map<String, dynamic>)['response'] as List;

    return (
      homeId: homeId,
      awayId: awayId,
      homeResults: _parseResults(fixturesOf(home), homeId),
      homeSquad: squadOf(home),
      awayResults: _parseResults(fixturesOf(away), awayId),
      awaySquad: squadOf(away),
      h2h: _parseH2h((data['h2h'] as Map<String, dynamic>)['response'] as List),
    );
  }
}
