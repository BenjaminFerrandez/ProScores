import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:proscores/data/football_repository.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  test('nationalTeamLogo prefers the national team and returns its logo',
      () async {
    final client = _MockClient();
    final body = jsonEncode({
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
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final logo = await repo.nationalTeamLogo('France');
    expect(logo, 'https://media.api-sports.io/football/teams/2.png');
  });

  test('nationalTeamLogo returns null when no results', () async {
    final client = _MockClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{"response": []}', 200));
    final repo = HttpFootballRepository(client);
    expect(await repo.nationalTeamLogo('Nowhere'), isNull);
  });

  test('parses upcoming fixtures', () async {
    final client = _MockClient();
    final body = jsonEncode({
      'response': [
        {
          'fixture': {
            'id': 101,
            'date': '2026-06-22T21:00:00+00:00',
          },
          'league': {'name': 'World Cup', 'round': 'Group Stage - 1'},
          'teams': {
            'home': {'id': 2, 'name': 'France', 'logo': 'fr.png'},
            'away': {'id': 6, 'name': 'Brazil', 'logo': 'br.png'},
          },
        }
      ]
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final fixtures = await repo.upcomingWorldCupFixtures();

    expect(fixtures, hasLength(1));
    expect(fixtures.first.id, 101);
    expect(fixtures.first.home.name, 'France');
    expect(fixtures.first.away.name, 'Brazil');
    expect(fixtures.first.kickoff.toUtc().hour, 21);
  });

  test('parses prediction percentages', () async {
    final client = _MockClient();
    final body = jsonEncode({
      'response': [
        {
          'predictions': {
            'percent': {'home': '48%', 'draw': '29%', 'away': '23%'}
          }
        }
      ]
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final pred = await repo.predictionFor(101);

    expect(pred.homeProb, closeTo(0.48, 1e-9));
    expect(pred.drawProb, closeTo(0.29, 1e-9));
    expect(pred.awayProb, closeTo(0.23, 1e-9));
  });

  test('throws on non-200', () async {
    final client = _MockClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('nope', 429));
    final repo = HttpFootballRepository(client);
    expect(repo.upcomingWorldCupFixtures(), throwsA(isA<ApiException>()));
  });

  test('resolveTeamId prefers the national team', () async {
    final client = _MockClient();
    final body = jsonEncode({
      'response': [
        {
          'team': {'id': 211, 'name': 'Benfica', 'national': false}
        },
        {
          'team': {'id': 27, 'name': 'Portugal', 'national': true}
        },
      ]
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    expect(await repo.resolveTeamId('Portugal'), 27);
  });

  test('recentResults keeps finished games, team perspective, recent first',
      () async {
    final client = _MockClient();
    final body = jsonEncode({
      'response': [
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
      ]
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final results = await repo.recentResults(2);
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

  test('squad reads positions and stats from /players (one page)', () async {
    final client = _MockClient();
    final body = jsonEncode({
      'paging': {'current': 1, 'total': 1},
      'response': [
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
      ]
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final players = await repo.squad(2);
    expect(players, hasLength(2));
    expect(players.first.name, 'A. Griezmann');
    expect(players.first.position, 'Attacker'); // accurate position
    expect(players.first.appearances, 7);
    expect(players.first.goals, 4);
  });

  test('headToHead parses meetings, most recent first', () async {
    final client = _MockClient();
    final body = jsonEncode({
      'response': [
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
      ]
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final h2h = await repo.headToHead(27, 9);
    expect(h2h, hasLength(2));
    expect(h2h.first.date.year, 2022); // sorted most recent first
    expect(h2h.first.homeGoals, 0);
    expect(h2h.first.awayGoals, 1);
  });

  test('matchStats parses the aggregated bundle in one call', () async {
    final client = _MockClient();
    Map<String, dynamic> fixture(int homeId, int awayId, String date) => {
          'fixture': {
            'date': date,
            'status': {'short': 'FT'}
          },
          'teams': {
            'home': {'id': homeId, 'name': 'France'},
            'away': {'id': awayId, 'name': 'Spain'},
          },
          'goals': {'home': 2, 'away': 1},
        };
    final body = jsonEncode({
      'homeId': 2,
      'awayId': 9,
      'h2h': {
        'response': [fixture(2, 9, '2022-09-27T18:00:00+00:00')]
      },
      'home': {
        'fixtures': {
          'response': [fixture(2, 9, '2024-06-01T18:00:00+00:00')]
        },
        'players': [
          {
            'response': [
              {
                'player': {'name': 'Mbappe'},
                'statistics': [
                  {
                    'games': {'appearences': 7, 'position': 'Attacker'},
                    'goals': {'total': 5}
                  }
                ]
              }
            ]
          }
        ],
      },
      'away': {
        'fixtures': {'response': <dynamic>[]},
        'players': [
          {'response': <dynamic>[]}
        ],
      },
    });
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpFootballRepository(client);
    final s = await repo.matchStats('France', 'Spain');

    expect(s.homeId, 2);
    expect(s.awayId, 9);
    expect(s.homeResults, hasLength(1));
    expect(s.homeResults.first.goalsFor, 2);
    expect(s.homeSquad.single.name, 'Mbappe');
    expect(s.homeSquad.single.goals, 5);
    expect(s.h2h, hasLength(1));
  });
}
