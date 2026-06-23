import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/combo.dart';
import '../models/risk_level.dart';
import '../services/combo_generator.dart';
import 'matches_provider.dart';

class ComboRequest {
  final double stake;
  final double target;
  final RiskLevel risk;
  const ComboRequest(
      {required this.stake, required this.target, required this.risk});

  @override
  bool operator ==(Object other) =>
      other is ComboRequest &&
      other.stake == stake &&
      other.target == target &&
      other.risk == risk;

  @override
  int get hashCode => Object.hash(stake, target, risk);
}

final comboProvider =
    FutureProvider.family<List<Combo>, ComboRequest>((ref, req) async {
  final fixtures = await ref.watch(worldCupFixturesProvider.future);
  // Build a candidate pool from each fixture's 1X2 selections.
  final pool = <CandidateBet>[];
  for (final f in fixtures) {
    for (final market in f.markets) {
      for (final sel in market.selections) {
        pool.add(CandidateBet(
            matchId: f.id, matchLabel: f.label, selection: sel));
      }
    }
  }
  return ComboGenerator.generate(
    stake: req.stake,
    target: req.target,
    risk: req.risk,
    pool: pool,
  );
});
