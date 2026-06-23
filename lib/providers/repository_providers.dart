import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../data/football_repository.dart';
import '../data/odds_repository.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final footballRepositoryProvider = Provider<FootballRepository>(
    (ref) => HttpFootballRepository(ref.watch(httpClientProvider)));

final oddsRepositoryProvider = Provider<OddsRepository>(
    (ref) => HttpOddsRepository(ref.watch(httpClientProvider)));
