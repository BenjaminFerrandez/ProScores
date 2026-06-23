import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_fixture.dart';
import 'repository_providers.dart';

final upcomingMatchesProvider =
    FutureProvider<List<MatchFixture>>((ref) async {
  final repo = ref.watch(footballRepositoryProvider);
  return repo.upcomingWorldCupFixtures();
});
