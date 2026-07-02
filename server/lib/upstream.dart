import 'package:http/http.dart' as http;
import 'secrets.dart';

/// A raw upstream response (status + body), passed straight back to the app so
/// its existing JSON parsing keeps working.
class UpstreamResponse {
  final int status;
  final String body;
  const UpstreamResponse(this.status, this.body);
}

/// Talks to The Odds API and API-Football. This is the only place the API keys
/// are used.
class Upstream {
  Upstream(this._client);
  final http.Client _client;

  static const _oddsBase =
      'https://api.the-odds-api.com/v4/sports/soccer_fifa_world_cup';
  static const _footballBase = 'https://v3.football.api-sports.io';

  Future<UpstreamResponse> _get(Uri uri, {Map<String, String>? headers}) async {
    final res = await _client.get(uri, headers: headers);
    return UpstreamResponse(res.statusCode, res.body);
  }

  Future<UpstreamResponse> worldCupOdds() => _get(Uri.parse(
      '$_oddsBase/odds?regions=eu&markets=h2h,totals,spreads'
      '&oddsFormat=decimal&apiKey=$oddsApiKey'));

  // API-Football wants the key in a header (The Odds API takes it as a query param).
  Map<String, String> get _footballHeaders =>
      {'x-apisports-key': footballApiKey};

  Future<UpstreamResponse> _football(String path) =>
      _get(Uri.parse('$_footballBase$path'), headers: _footballHeaders);

  Future<UpstreamResponse> teamSearch(String name) =>
      _football('/teams?search=${Uri.encodeQueryComponent(name)}');

  Future<UpstreamResponse> teamFixtures(int teamId, int season) =>
      _football('/fixtures?team=$teamId&season=$season');

  Future<UpstreamResponse> teamPlayers(int teamId, int season, int page) =>
      _football('/players?team=$teamId&season=$season&page=$page');

  Future<UpstreamResponse> headToHead(int home, int away) =>
      _football('/fixtures/headtohead?h2h=$home-$away');
}
