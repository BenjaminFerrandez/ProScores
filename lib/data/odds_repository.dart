import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'football_repository.dart' show ApiException;

/// A World Cup event as returned by The Odds API, with its 1X2 (h2h) odds.
class OddsEvent {
  final String id;
  final DateTime commenceTime;
  final String homeTeam;
  final String awayTeam;

  /// Ordered [home, draw, away]. Null when no bookmaker h2h odds are available.
  final List<double>? h2h;

  const OddsEvent({
    required this.id,
    required this.commenceTime,
    required this.homeTeam,
    required this.awayTeam,
    this.h2h,
  });
}

abstract class OddsRepository {
  /// Upcoming World Cup events with their head-to-head odds, in a single call.
  Future<List<OddsEvent>> fetchWorldCupEvents();
}

class HttpOddsRepository implements OddsRepository {
  HttpOddsRepository(this.client);
  final http.Client client;

  static const _base =
      'https://api.the-odds-api.com/v4/sports/soccer_fifa_world_cup/odds';

  @override
  Future<List<OddsEvent>> fetchWorldCupEvents() async {
    final uri = Uri.parse(
        '$_base?regions=eu&markets=h2h&oddsFormat=decimal&apiKey=$oddsApiKey');
    final res = await client.get(uri, headers: const {});
    if (res.statusCode != 200) {
      throw ApiException('odds HTTP ${res.statusCode}');
    }
    final games = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return games.map(_parseEvent).toList();
  }

  OddsEvent _parseEvent(Map<String, dynamic> g) {
    final home = g['home_team'] as String;
    final away = g['away_team'] as String;
    return OddsEvent(
      id: g['id'] as String,
      commenceTime: DateTime.parse(g['commence_time'] as String),
      homeTeam: home,
      awayTeam: away,
      h2h: _extractH2h(g, home, away),
    );
  }

  /// Reads the first bookmaker's h2h market and returns [home, draw, away].
  List<double>? _extractH2h(
      Map<String, dynamic> g, String home, String away) {
    final bookmakers =
        (g['bookmakers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (bookmakers.isEmpty) return null;
    final markets =
        (bookmakers.first['markets'] as List).cast<Map<String, dynamic>>();
    final h2h = markets.where((m) => m['key'] == 'h2h');
    if (h2h.isEmpty) return null;
    final outcomes =
        (h2h.first['outcomes'] as List).cast<Map<String, dynamic>>();
    double? price(String name) {
      for (final o in outcomes) {
        if (o['name'] == name) return (o['price'] as num).toDouble();
      }
      return null;
    }

    final ph = price(home);
    final pd = price('Draw');
    final pa = price(away);
    if (ph == null || pd == null || pa == null) return null;
    return [ph, pd, pa];
  }
}
