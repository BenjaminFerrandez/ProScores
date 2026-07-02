import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:proscores/data/football_repository.dart';

class _MockClient extends Mock implements http.Client {}

/// Wraps raw API-Football-style payloads in the aggregated /match/stats
/// bundle shape the server returns.
String bundle({
  int homeId = 2,
  int awayId = 9,
  List<dynamic> homeFixtures = const [],
  List<dynamic> awayFixtures = const [],
  List<dynamic> homePlayers = const [],
  List<dynamic> awayPlayers = const [],
  List<dynamic> h2h = const [],
}) =>
    jsonEncode({
      'homeId': homeId,
      'awayId': awayId,
      'h2h': {'response': h2h},
      'home': {
        'fixtures': {'response': homeFixtures},
        'players': [
          {'response': homePlayers}
        ],
      },
      'away': {
        'fixtures': {'response': awayFixtures},
        'players': [
          {'response': awayPlayers}
        ],
      },
    });

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  late _MockClient client;
  late HttpFootballRepository repo;

  setUp(() {
    client = _MockClient();
    repo = HttpFootballRepository(client);
  });

  void answerWith(String body, [int status = 200]) =>
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(body, status));

  test('nationalTeamLogo prefers the national team and returns its logo',
      () async {
    answerWith(jsonEncode({
      'response': [
        {
          'team': {
            'id': 2,
            'name': 'France',
            'national': true,
            'logo': 'https://media.api-sports.io/football/teams/2.png',
          }
        },
        {
          'team': {
            'id': 81,
            'name': 'Marseille',
            'national': false,
            'logo': 'https://media.api-sports.io/football/teams/81.png',
          }
        },
      ]
    }));

    final logo = await repo.nationalTeamLogo('France');
    expect(logo, 'https://media.api-sports.io/football/teams/2.png');
  });

  test('nationalTeamLogo returns null when no results', () async {
    answerWith('{"response": []}');
    expect(await repo.nationalTeamLogo('Nowhere'), isNull);
  });

  test('matchStats throws on non-200', () async {
    answerWith('nope', 429);
    expect(repo.matchStats('France', 'Spain'), throwsA(isA<ApiException>()));
  });

  test('results keep finished games, team perspective, recent first',
      () async {
    answerWith(bundle(homeFixtures: [
      {
        'fixture': {
          'date': '2024-06-01T18:00:00+00:00',
          'status': {'short': 'FT'}
        },
        'teams': {
          'home': {'id': 2, 'name': 'France'},
          'away': {'id': 9, 'name': 'Spain'},
        },
        'goals': {'home': 2, 'away': 1},
      },
      {
        // away game for France, won 0-3
        'fixture': {
          'date': '2024-09-01T18:00:00+00:00',
          'status': {'short': 'FT'}
        },
        'teams': {
          'home': {'id': 9, 'name': 'Spain'},
          'away': {'id': 2, 'name': 'France'},
        },
        'goals': {'home': 0, 'away': 3},
      },
      {
        // not finished -> skipped
        'fixture': {
          'date': '2024-10-01T18:00:00+00:00',
          'status': {'short': 'NS'}
        },
        'teams': {
          'home': {'id': 2, 'name': 'France'},
          'away': {'id': 9, 'name': 'Spain'},
        },
        'goals': {'home': null, 'away': null},
      },
    ]));

    final results = (await repo.matchStats('France', 'Spain')).homeResults;
    expect(results, hasLength(2)); // NS skipped
    // most recent first = the September away win
    expect(results.first.date.month, 9);
    expect(results.first.isHome, isFalse);
    expect(results.first.opponent, 'Spain');
    expect(results.first.goalsFor, 3);
    expect(results.first.goalsAgainst, 0);
    expect(results.first.outcome, 'W');
    expect(results.last.outcome, 'W'); // June 2-1 home win
  });

  test('squad reads positions and stats from the players pages', () async {
    answerWith(bundle(homePlayers: [
      {
        'player': {'id': 1, 'name': 'A. Griezmann'},
        'statistics': [
          {
            'games': {'appearences': 7, 'position': 'Attacker'},
            'goals': {'total': 4}
          }
        ]
      },
      {
        'player': {'id': 2, 'name': 'A. Tchouameni'},
        'statistics': [
          {
            'games': {'appearences': 6, 'position': 'Midfielder'},
            'goals': {'total': 0}
          }
        ]
      },
    ]));

    final players = (await repo.matchStats('France', 'Spain')).homeSquad;
    expect(players, hasLength(2));
    expect(players.first.name, 'A. Griezmann');
    expect(players.first.position, 'Attacker'); // accurate position
    expect(players.first.appearances, 7);
    expect(players.first.goals, 4);
  });

  test('h2h parses meetings, most recent first', () async {
    answerWith(bundle(h2h: [
      {
        'fixture': {'date': '2018-06-15T18:00:00+00:00'},
        'teams': {
          'home': {'name': 'Portugal'},
          'away': {'name': 'Spain'},
        },
        'goals': {'home': 3, 'away': 3},
      },
      {
        'fixture': {'date': '2022-09-27T18:00:00+00:00'},
        'teams': {
          'home': {'name': 'Portugal'},
          'away': {'name': 'Spain'},
        },
        'goals': {'home': 0, 'away': 1},
      },
    ]));

    final h2h = (await repo.matchStats('Portugal', 'Spain')).h2h;
    expect(h2h, hasLength(2));
    expect(h2h.first.date.year, 2022); // sorted most recent first
    expect(h2h.first.homeGoals, 0);
    expect(h2h.first.awayGoals, 1);
  });

  test('matchStats maps team ids from the bundle', () async {
    answerWith(bundle(homeId: 27, awayId: 9));
    final s = await repo.matchStats('Portugal', 'Spain');
    expect(s.homeId, 27);
    expect(s.awayId, 9);
    expect(s.homeResults, isEmpty);
    expect(s.awaySquad, isEmpty);
  });
}
