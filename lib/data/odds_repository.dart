import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'football_repository.dart' show ApiException;

abstract class OddsRepository {
  /// Map of market code -> ordered odds.
  /// '1x2' -> [home, draw, away].
  Future<Map<String, List<double>>> marketOddsFor(
      String homeTeam, String awayTeam);
}

class HttpOddsRepository implements OddsRepository {
  HttpOddsRepository(this.client);
  final http.Client client;

  static const _base =
      'https://api.the-odds-api.com/v4/sports/soccer_fifa_world_cup/odds';

  @override
  Future<Map<String, List<double>>> marketOddsFor(
      String homeTeam, String awayTeam) async {
    final uri = Uri.parse(
        '$_base?regions=eu&markets=h2h&oddsFormat=decimal&apiKey=$oddsApiKey');
    final res = await client.get(uri, headers: const {});
    if (res.statusCode != 200) {
      throw ApiException('odds HTTP ${res.statusCode}');
    }
    final games = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    final game = games.firstWhere(
      (g) => g['home_team'] == homeTeam && g['away_team'] == awayTeam,
      orElse: () => <String, dynamic>{},
    );
    if (game.isEmpty) return {};

    final bookmakers = (game['bookmakers'] as List).cast<Map<String, dynamic>>();
    if (bookmakers.isEmpty) return {};
    final markets =
        (bookmakers.first['markets'] as List).cast<Map<String, dynamic>>();
    final result = <String, List<double>>{};

    final h2h = markets.where((m) => m['key'] == 'h2h');
    if (h2h.isNotEmpty) {
      final outcomes =
          (h2h.first['outcomes'] as List).cast<Map<String, dynamic>>();
      double price(String name) => (outcomes.firstWhere(
          (o) => o['name'] == name)['price'] as num).toDouble();
      result['1x2'] = [price(homeTeam), price('Draw'), price(awayTeam)];
    }
    return result;
  }
}
