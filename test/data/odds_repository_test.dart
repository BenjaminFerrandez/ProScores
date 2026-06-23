import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:proscores/data/odds_repository.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  test('extracts 1x2 odds for the matching game', () async {
    final client = _MockClient();
    final body = jsonEncode([
      {
        'home_team': 'France',
        'away_team': 'Brazil',
        'bookmakers': [
          {
            'markets': [
              {
                'key': 'h2h',
                'outcomes': [
                  {'name': 'France', 'price': 2.10},
                  {'name': 'Brazil', 'price': 3.05},
                  {'name': 'Draw', 'price': 3.40},
                ]
              }
            ]
          }
        ]
      }
    ]);
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpOddsRepository(client);
    final odds = await repo.marketOddsFor('France', 'Brazil');

    // ordered home, draw, away
    expect(odds['1x2'], [2.10, 3.40, 3.05]);
  });

  test('returns empty map when no game matches', () async {
    final client = _MockClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));
    final repo = HttpOddsRepository(client);
    final odds = await repo.marketOddsFor('France', 'Brazil');
    expect(odds, isEmpty);
  });
}
