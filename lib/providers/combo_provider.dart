import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/combo.dart';
import '../models/combo_sort.dart';
import '../models/risk_level.dart';
import '../services/combo_generator.dart';
import 'matches_provider.dart';

class ComboRequest {
  final double stake;
  final double target;

  /// Optional risk filter. Empty = all risk bands.
  final Set<RiskLevel> risks;

  /// Optional team filter (team names). Empty = all teams.
  final Set<String> teams;

  /// How to order the results.
  final ComboSort sort;

  const ComboRequest({
    required this.stake,
    required this.target,
    this.risks = const {},
    this.teams = const {},
    this.sort = ComboSort.probabilityDesc,
  });

  ComboRequest copyWith({ComboSort? sort}) => ComboRequest(
        stake: stake,
        target: target,
        risks: risks,
        teams: teams,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is ComboRequest &&
      other.stake == stake &&
      other.target == target &&
      other.sort == sort &&
      _sameSet(other.risks, risks) &&
      _sameSet(other.teams, teams);

  bool _sameSet(Set o, Set s) => o.length == s.length && o.containsAll(s);

  @override
  int get hashCode => Object.hash(stake, target, sort,
      Object.hashAllUnordered(risks),
      Object.hashAllUnordered(teams));
}

/// Unique team names that have an upcoming match, sorted alphabetically.
/// Used to populate the team filter in the create-prono screen.
final upcomingTeamsProvider = FutureProvider<List<String>>((ref) async {
  final fixtures = await ref.watch(worldCupFixturesProvider.future);
  final names = <String>{};
  for (final f in fixtures) {
    names.add(f.home.name);
    names.add(f.away.name);
  }
  final list = names.toList()..sort();
  return list;
});

final comboProvider =
    FutureProvider.family<List<Combo>, ComboRequest>((ref, req) async {
  final fixtures = await ref.watch(worldCupFixturesProvider.future);
  // Build a candidate pool, honoring the optional team filter.
  final pool = <CandidateBet>[];
  for (final f in fixtures) {
    if (req.teams.isNotEmpty &&
        !req.teams.contains(f.home.name) &&
        !req.teams.contains(f.away.name)) {
      continue;
    }
    for (final market in f.markets) {
      for (final sel in market.selections) {
        pool.add(CandidateBet(
            matchId: f.id,
            matchLabel: f.label,
            market: market.type,
            selection: sel));
      }
    }
  }
  return ComboGenerator.generate(
    stake: req.stake,
    target: req.target,
    risks: req.risks,
    pool: pool,
    sort: req.sort,
    maxResults: kComboMaxResults,
  );
});
