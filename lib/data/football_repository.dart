import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../config/constants.dart';
import '../models/match_fixture.dart';
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

  /// Logo (crest) URL for a national team given its name, or null if unknown.
  Future<String?> nationalTeamLogo(String teamName);
}

class HttpFootballRepository implements FootballRepository {
  HttpFootballRepository(this.client);
  final http.Client client;

  static const _base = 'https://v3.football.api-sports.io';
  Map<String, String> get _headers => {'x-apisports-key': footballApiKey};

  @override
  Future<String?> nationalTeamLogo(String teamName) async {
    final uri = Uri.parse('$_base/teams?search=${Uri.encodeQueryComponent(teamName)}');
    final res = await client.get(uri, headers: _headers);
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
}
