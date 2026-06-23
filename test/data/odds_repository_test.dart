import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:proscores/data/football_repository.dart' show ApiException;
import 'package:proscores/data/odds_repository.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  test('parses events with h2h odds ordered [home, draw, away]', () async {
    final client = _MockClient();
    final body = jsonEncode([
      {
        'id': '8ba93d190f1f934e33862a97a6353a6e',
        'commence_time': '2026-06-23T17:00:00Z',
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
    final events = await repo.fetchWorldCupEvents();

    expect(events, hasLength(1));
    final e = events.first;
    expect(e.id, '8ba93d190f1f934e33862a97a6353a6e');
    expect(e.homeTeam, 'France');
    expect(e.awayTeam, 'Brazil');
    expect(e.commenceTime.toUtc().hour, 17);
    expect(e.h2h, [2.10, 3.40, 3.05]); // home, draw, away
  });

  test('keeps event but leaves h2h null when no bookmaker odds', () async {
    final client = _MockClient();
    final body = jsonEncode([
      {
        'id': 'abc',
        'commence_time': '2026-06-24T18:00:00Z',
        'home_team': 'Spain',
        'away_team': 'Japan',
        'bookmakers': <dynamic>[],
      }
    ]);
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final repo = HttpOddsRepository(client);
    final events = await repo.fetchWorldCupEvents();
    expect(events.single.h2h, isNull);
  });

  test('throws on non-200', () async {
    final client = _MockClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('nope', 401));
    final repo = HttpOddsRepository(client);
    expect(repo.fetchWorldCupEvents(), throwsA(isA<ApiException>()));
  });
}
