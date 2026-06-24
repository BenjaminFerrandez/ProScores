import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../config/constants.dart';
import '../models/match_fixture.dart';
import '../models/match_stats.dart';
import '../models/prediction.dart';
import '../models/team.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

abstract class FootballRepository {
  Future<List<MatchFixture>> upcomingWorldCupFixtures();
  Future<Prediction> predictionFor(int fixtureId);

  /// Resolves a (national) team name to its API-Football id, or null.
  Future<int?> resolveTeamId(String name);

  /// Recent finished results for a team, most recent first.
  Future<List<TeamResult>> recentResults(int teamId);

  /// Squad of a team with each player's recent-season position and stats.
  Future<List<SquadPlayer>> squad(int teamId);

  /// Past meetings between two teams, most recent first.
  Future<List<H2HMatch>> headToHead(int homeId, int awayId);
}

class HttpFootballRepository implements FootballRepository {
  HttpFootballRepository(this.client);
  final http.Client client;

  static const _base = 'https://v3.football.api-sports.io';
  Map<String, String> get _headers => {'x-apisports-key': footballApiKey};

  @override
  Future<List<MatchFixture>> upcomingWorldCupFixtures() async {
    final uri = Uri.parse(
        '$_base/fixtures?league=$kWorldCupLeagueId&season=$kSeason&next=20');
    final res = await client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw ApiException('fixtures HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['response'] as List).cast<Map<String, dynamic>>();
    return list.map(_parseFixture).toList();
  }

  MatchFixture _parseFixture(Map<String, dynamic> j) {
    final fixture = j['fixture'] as Map<String, dynamic>;
    final league = j['league'] as Map<String, dynamic>;
    final teams = j['teams'] as Map<String, dynamic>;
    final home = teams['home'] as Map<String, dynamic>;
    final away = teams['away'] as Map<String, dynamic>;
    return MatchFixture(
      id: fixture['id'] as int,
      competition: league['name'] as String? ?? 'World Cup',
      group: league['round'] as String?,
      kickoff: DateTime.parse(fixture['date'] as String),
      home: Team(
          id: home['id'] as int,
          name: home['name'] as String,
          flag: home['logo'] as String?),
      away: Team(
          id: away['id'] as int,
          name: away['name'] as String,
          flag: away['logo'] as String?),
    );
  }

  @override
  Future<Prediction> predictionFor(int fixtureId) async {
    final uri = Uri.parse('$_base/predictions?fixture=$fixtureId');
    final res = await client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw ApiException('predictions HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final response = (data['response'] as List).cast<Map<String, dynamic>>();
    if (response.isEmpty) throw ApiException('no prediction');
    final percent = (response.first['predictions']
        as Map<String, dynamic>)['percent'] as Map<String, dynamic>;
    double pct(String k) =>
        double.parse((percent[k] as String).replaceAll('%', '')) / 100.0;
    return Prediction(
        homeProb: pct('home'), drawProb: pct('draw'), awayProb: pct('away'));
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, String what) async {
    final res = await client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw ApiException('$what HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  @override
  Future<int?> resolveTeamId(String name) async {
    final uri = Uri.parse('$_base/teams?search=${Uri.encodeQueryComponent(name)}');
    final data = await _getJson(uri, 'teams');
    final list = (data['response'] as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    // Prefer a national team when several share the name.
    final national = list.firstWhere(
      (e) => (e['team'] as Map<String, dynamic>)['national'] == true,
      orElse: () => list.first,
    );
    return (national['team'] as Map<String, dynamic>)['id'] as int;
  }

  static const _finished = {'FT', 'AET', 'PEN'};

  @override
  Future<List<TeamResult>> recentResults(int teamId) async {
    final uri =
        Uri.parse('$_base/fixtures?team=$teamId&season=$kStatsSeason');
    final data = await _getJson(uri, 'fixtures');
    final list = (data['response'] as List).cast<Map<String, dynamic>>();
    final results = <TeamResult>[];
    for (final f in list) {
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

  @override
  Future<List<SquadPlayer>> squad(int teamId) async {
    // The /players endpoint carries each player's real position (games.position)
    // and stats, unlike /players/squads whose positions are unreliable.
    final players = <SquadPlayer>[];
    var page = 1;
    var totalPages = 1;
    do {
      final uri = Uri.parse(
          '$_base/players?team=$teamId&season=$kStatsSeason&page=$page');
      final data = await _getJson(uri, 'players');
      final paging = data['paging'] as Map<String, dynamic>?;
      totalPages = (paging?['total'] as num?)?.toInt() ?? 1;
      final list = (data['response'] as List).cast<Map<String, dynamic>>();
      for (final p in list) {
        final player = p['player'] as Map<String, dynamic>;
        final stats =
            (p['statistics'] as List?)?.cast<Map<String, dynamic>>() ??
                const [];
        String? position;
        var apps = 0;
        var goals = 0;
        for (final s in stats) {
          final games = s['games'] as Map<String, dynamic>?;
          position ??= games?['position'] as String?;
          apps += (games?['appearences'] as num?)?.toInt() ?? 0;
          goals +=
              ((s['goals'] as Map<String, dynamic>?)?['total'] as num?)
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
      page++;
    } while (page <= totalPages && page <= 6); // safety cap
    return players;
  }

  @override
  Future<List<H2HMatch>> headToHead(int homeId, int awayId) async {
    final uri =
        Uri.parse('$_base/fixtures/headtohead?h2h=$homeId-$awayId');
    final data = await _getJson(uri, 'head to head');
    final list = (data['response'] as List).cast<Map<String, dynamic>>();
    final matches = list.map((f) {
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
}
