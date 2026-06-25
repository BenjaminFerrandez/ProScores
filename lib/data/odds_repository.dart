import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'football_repository.dart' show ApiException;

/// Over/under goals line for an event (a single, featured totals line).
class TotalsOdds {
  final double point; // e.g. 2.5
  final double overOdd;
  final double underOdd;
  const TotalsOdds(
      {required this.point, required this.overOdd, required this.underOdd});
}

/// Asian/European handicap line for an event (home vs away).
class SpreadsOdds {
  final double homePoint; // e.g. -1.5
  final double homeOdd;
  final double awayPoint; // e.g. +1.5
  final double awayOdd;
  const SpreadsOdds({
    required this.homePoint,
    required this.homeOdd,
    required this.awayPoint,
    required this.awayOdd,
  });
}

/// A World Cup event as returned by The Odds API, with its featured markets.
class OddsEvent {
  final String id;
  final DateTime commenceTime;
  final String homeTeam;
  final String awayTeam;

  /// Ordered [home, draw, away]. Null when no bookmaker h2h odds are available.
  final List<double>? h2h;

  /// Market-consensus fair probabilities [home, draw, away], averaged across
  /// every bookmaker (margin removed). Used to flag value bets.
  final List<double>? h2hConsensus;

  /// Over/under goals line. Null when no bookmaker offers it.
  final TotalsOdds? totals;

  /// Handicap line. Null when no bookmaker offers it.
  final SpreadsOdds? spreads;

  const OddsEvent({
    required this.id,
    required this.commenceTime,
    required this.homeTeam,
    required this.awayTeam,
    this.h2h,
    this.h2hConsensus,
    this.totals,
    this.spreads,
  });
}

abstract class OddsRepository {
  /// Upcoming World Cup events with their featured odds, in a single call.
  Future<List<OddsEvent>> fetchWorldCupEvents();
}

class HttpOddsRepository implements OddsRepository {
  HttpOddsRepository(this.client);
  final http.Client client;

  @override
  Future<List<OddsEvent>> fetchWorldCupEvents() async {
    // Served (and cached) by our backend, which holds the API key.
    final uri = Uri.parse('$kServerBaseUrl/odds/worldcup');
    final res = await client.get(uri);
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
      h2hConsensus: _extractH2hConsensus(g, home, away),
      totals: _extractTotals(g),
      spreads: _extractSpreads(g, home, away),
    );
  }

  /// Average, across every bookmaker, of the margin-removed h2h probabilities.
  /// This is a better estimate of the "true" outcome probability than any
  /// single bookmaker, so it lets us spot value (a price that beats it).
  List<double>? _extractH2hConsensus(
      Map<String, dynamic> g, String home, String away) {
    final bookmakers =
        (g['bookmakers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final sums = [0.0, 0.0, 0.0];
    var count = 0;
    for (final b in bookmakers) {
      final markets =
          (b['markets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final h2h = markets.where((m) => m['key'] == 'h2h');
      if (h2h.isEmpty) continue;
      final outcomes = (h2h.first['outcomes'] as List).cast<Map<String, dynamic>>();
      double? price(String name) {
        for (final o in outcomes) {
          if (o['name'] == name) return (o['price'] as num).toDouble();
        }
        return null;
      }

      final ph = price(home), pd = price('Draw'), pa = price(away);
      if (ph == null || pd == null || pa == null) continue;
      final implied = [1 / ph, 1 / pd, 1 / pa];
      final s = implied[0] + implied[1] + implied[2];
      for (var i = 0; i < 3; i++) {
        sums[i] += implied[i] / s; // this bookmaker's margin-removed prob
      }
      count++;
    }
    if (count == 0) return null;
    final avg = [sums[0] / count, sums[1] / count, sums[2] / count];
    final t = avg[0] + avg[1] + avg[2];
    return [avg[0] / t, avg[1] / t, avg[2] / t];
  }

  /// Returns the outcomes of the first bookmaker offering [marketKey], or null.
  List<Map<String, dynamic>>? _firstMarketOutcomes(
      Map<String, dynamic> g, String marketKey) {
    final bookmakers =
        (g['bookmakers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    for (final b in bookmakers) {
      final markets =
          (b['markets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final m in markets) {
        if (m['key'] == marketKey) {
          return (m['outcomes'] as List).cast<Map<String, dynamic>>();
        }
      }
    }
    return null;
  }

  /// Reads the first bookmaker's h2h market and returns [home, draw, away].
  List<double>? _extractH2h(
      Map<String, dynamic> g, String home, String away) {
    final outcomes = _firstMarketOutcomes(g, 'h2h');
    if (outcomes == null) return null;
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

  /// Reads the first bookmaker's totals market (Over/Under on one line).
  TotalsOdds? _extractTotals(Map<String, dynamic> g) {
    final outcomes = _firstMarketOutcomes(g, 'totals');
    if (outcomes == null) return null;
    Map<String, dynamic>? side(String name) {
      for (final o in outcomes) {
        if (o['name'] == name) return o;
      }
      return null;
    }

    final over = side('Over');
    final under = side('Under');
    if (over == null || under == null) return null;
    return TotalsOdds(
      point: (over['point'] as num).toDouble(),
      overOdd: (over['price'] as num).toDouble(),
      underOdd: (under['price'] as num).toDouble(),
    );
  }

  /// Reads the first bookmaker's spreads market (handicap, named by team).
  SpreadsOdds? _extractSpreads(
      Map<String, dynamic> g, String home, String away) {
    final outcomes = _firstMarketOutcomes(g, 'spreads');
    if (outcomes == null) return null;
    Map<String, dynamic>? side(String name) {
      for (final o in outcomes) {
        if (o['name'] == name) return o;
      }
      return null;
    }

    final h = side(home);
    final a = side(away);
    if (h == null || a == null) return null;
    return SpreadsOdds(
      homePoint: (h['point'] as num).toDouble(),
      homeOdd: (h['price'] as num).toDouble(),
      awayPoint: (a['point'] as num).toDouble(),
      awayOdd: (a['price'] as num).toDouble(),
    );
  }
}
