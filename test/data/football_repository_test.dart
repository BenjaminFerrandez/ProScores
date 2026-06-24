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
}
