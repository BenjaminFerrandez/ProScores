import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:proscores_server/cache.dart';
import 'package:proscores_server/upstream.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/open.dart';

// Cache durations (seconds). 0 == never expires.
const _forever = 0;
const _ttlOdds = 300; // 5 min — odds move
const _ttlTeamFixtures = 21600; // 6 h
const _ttlPlayers = 86400; // 1 day — squads rarely change
const _ttlH2h = 604800; // 7 days — historic

late final Cache _cache;
late final Upstream _up;

Future<void> main() async {
  _configureSqlite();
  _cache = Cache.open('cache.db');
  _up = Upstream(http.Client());

  final router = Router()
    ..get('/health', _health)
    ..get('/odds/worldcup', _oddsWorldCup)
    ..get('/football/teams/search', _teamSearch)
    ..get('/football/teams/<id|[0-9]+>/players', _teamPlayers)
    ..get('/football/teams/<id|[0-9]+>/fixtures', _teamFixtures)
    ..get('/football/h2h', _h2h)
    ..get('/match/stats', _matchStats);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8090);
  stdout.writeln('ProScores server on http://${server.address.host}:${server.port}'
      ' (cache: ${_cache.size} entries)');
}

Response _health(Request r) => _json(
    jsonEncode({'status': 'ok', 'cacheEntries': _cache.size}), 200, 'LIVE');

Future<Response> _oddsWorldCup(Request r) =>
    _cached('odds:worldcup', _ttlOdds, _up.worldCupOdds);

Future<Response> _teamSearch(Request r) {
  final name = (r.url.queryParameters['name'] ?? '').trim();
  if (name.isEmpty) return Future.value(_bad('missing ?name'));
  // Forever: a team's id never changes.
  return _cached('team:search:${name.toLowerCase()}', _forever,
      () => _up.teamSearch(name));
}

Future<Response> _teamPlayers(Request r, String id) {
  final season = _season(r);
  final page = int.tryParse(r.url.queryParameters['page'] ?? '1') ?? 1;
  return _cached('team:$id:players:$season:$page', _ttlPlayers,
      () => _up.teamPlayers(int.parse(id), season, page));
}

Future<Response> _teamFixtures(Request r, String id) {
  final season = _season(r);
  return _cached('team:$id:fixtures:$season', _ttlTeamFixtures,
      () => _up.teamFixtures(int.parse(id), season));
}

Future<Response> _h2h(Request r) {
  final home = int.tryParse(r.url.queryParameters['home'] ?? '');
  final away = int.tryParse(r.url.queryParameters['away'] ?? '');
  if (home == null || away == null) {
    return Future.value(_bad('missing ?home & ?away'));
  }
  return _cached('h2h:$home:$away', _ttlH2h, () => _up.headToHead(home, away));
}

// Aggregated "match stats": one app call -> team ids + form + squads + h2h.
Future<Response> _matchStats(Request r) async {
  final home = (r.url.queryParameters['home'] ?? '').trim();
  final away = (r.url.queryParameters['away'] ?? '').trim();
  if (home.isEmpty || away.isEmpty) return _bad('missing ?home & ?away');
  final season = _season(r);
  try {
    final homeId = await _resolveId(home);
    final awayId = await _resolveId(away);
    if (homeId == null || awayId == null) {
      return _json(jsonEncode({'error': 'team not found'}), 404, 'AGG');
    }
    final h2h = await _bodyCached(
        'h2h:$homeId:$awayId', _ttlH2h, () => _up.headToHead(homeId, awayId));
    final homeFix = await _bodyCached('team:$homeId:fixtures:$season',
        _ttlTeamFixtures, () => _up.teamFixtures(homeId, season));
    final awayFix = await _bodyCached('team:$awayId:fixtures:$season',
        _ttlTeamFixtures, () => _up.teamFixtures(awayId, season));
    final homePlayers = await _allPlayers(homeId, season);
    final awayPlayers = await _allPlayers(awayId, season);

    final bundle = {
      'homeId': homeId,
      'awayId': awayId,
      'h2h': jsonDecode(h2h.body),
      'home': {'fixtures': jsonDecode(homeFix.body), 'players': homePlayers},
      'away': {'fixtures': jsonDecode(awayFix.body), 'players': awayPlayers},
    };
    return _json(jsonEncode(bundle), 200, 'AGG');
  } catch (e) {
    return _json(jsonEncode({'error': 'aggregation failed: $e'}), 502, 'ERROR');
  }
}

/// Resolves a team name to its API-Football id (national preferred).
Future<int?> _resolveId(String name) async {
  final res = await _bodyCached('team:search:${name.toLowerCase()}', _forever,
      () => _up.teamSearch(name));
  if (res.status != 200) return null;
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final list =
      (data['response'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  if (list.isEmpty) return null;
  final national = list.firstWhere(
    (e) => (e['team'] as Map<String, dynamic>)['national'] == true,
    orElse: () => list.first,
  );
  return (national['team'] as Map<String, dynamic>)['id'] as int;
}

/// Every page of a team's players.
Future<List<dynamic>> _allPlayers(int teamId, int season) async {
  final pages = <dynamic>[];
  var page = 1;
  var total = 1;
  do {
    final res = await _bodyCached('team:$teamId:players:$season:$page',
        _ttlPlayers, () => _up.teamPlayers(teamId, season, page));
    if (res.status != 200) break;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    pages.add(data);
    total =
        ((data['paging'] as Map<String, dynamic>?)?['total'] as num?)?.toInt() ??
            1;
    page++;
  } while (page <= total && page <= 6);
  return pages;
}

// CORS, so the Flutter web build in Chrome can call us.
const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': '*',
};

Middleware _cors() => (Handler handler) => (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(null, headers: _corsHeaders);
      }
      final response = await handler(request);
      return response.change(headers: _corsHeaders);
    };

/// Returns the cached or freshly-fetched (status, body). Caches 200 responses.
Future<({int status, String body})> _bodyCached(
    String key, int ttl, Future<UpstreamResponse> Function() fetch) async {
  final hit = _cache.get(key);
  if (hit != null) return (status: hit.status, body: hit.body);
  final up = await fetch();
  if (up.status == 200) _cache.put(key, up.body, up.status, ttl);
  return (status: up.status, body: up.body);
}

Future<Response> _cached(
    String key, int ttl, Future<UpstreamResponse> Function() fetch) async {
  final hit = _cache.get(key);
  if (hit != null) return _json(hit.body, hit.status, 'HIT', age: hit.ageSeconds);
  try {
    final up = await fetch();
    if (up.status == 200) _cache.put(key, up.body, up.status, ttl);
    return _json(up.body, up.status, 'MISS');
  } catch (e) {
    return _json(jsonEncode({'error': 'upstream failed: $e'}), 502, 'ERROR');
  }
}

Response _json(String body, int status, String cache, {int? age}) =>
    Response(status, body: body, headers: {
      'content-type': 'application/json; charset=utf-8',
      'x-cache': cache,
      if (age != null) 'x-cache-age': '$age',
    });

Response _bad(String message) =>
    _json(jsonEncode({'error': message}), 400, 'LIVE');

int _season(Request r) =>
    int.tryParse(r.url.queryParameters['season'] ?? '') ?? 2024;

/// On Windows, load the sqlite3.dll committed next to the server.
void _configureSqlite() {
  if (!Platform.isWindows) return;
  open.overrideFor(OperatingSystem.windows, () {
    for (final p in ['sqlite3.dll', 'server/sqlite3.dll']) {
      final f = File(p);
      if (f.existsSync()) return DynamicLibrary.open(f.absolute.path);
    }
    return DynamicLibrary.open('sqlite3.dll');
  });
}
