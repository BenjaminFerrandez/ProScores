import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_fixture.dart';
import 'matches_provider.dart';

/// Looks up a single fixture (with its markets already populated) from the
/// cached World Cup fixtures list. No extra network call.
final matchDetailProvider =
    FutureProvider.family<MatchFixture, int>((ref, fixtureId) async {
  final fixtures = await ref.watch(worldCupFixturesProvider.future);
  return fixtures.firstWhere((f) => f.id == fixtureId);
});
