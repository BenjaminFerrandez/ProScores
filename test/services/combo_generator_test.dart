import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/models/selection.dart';
import 'package:proscores/services/combo_generator.dart';

CandidateBet bet(int matchId, String label, double odd, double prob) =>
    CandidateBet(
      matchId: matchId,
      matchLabel: 'match$matchId',
      selection: Selection(
          label: label,
          odd: odd,
          adjustedProbability: prob,
          risk: riskLevelFor(prob)),
    );

// helper so the test pool is tagged with a risk level
RiskLevel riskLevelFor(double p) =>
    p >= 0.5 ? RiskLevel.modere : RiskLevel.risque;

void main() {
  test('finds a 2-leg combo near the target multiplier', () {
    // target multiplier 2x; legs 1.4*1.45 = 2.03 within ±10%
    final pool = [
      bet(1, 'A', 1.40, 0.60),
      bet(2, 'B', 1.45, 0.58),
      bet(3, 'C', 5.00, 0.55), // far off target alone
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.modere,
      pool: pool,
    );
    expect(combos, isNotEmpty);
    expect(combos.first.legs.length, 2);
    expect(combos.first.totalOdds, closeTo(2.03, 0.01));
    expect(combos.first.potentialWin, closeTo(20.3, 0.1));
    // probability is the product of leg probabilities
    expect(combos.first.probability, closeTo(0.60 * 0.58, 1e-9));
  });

  test('never uses two legs from the same match', () {
    final pool = [
      bet(1, 'A', 1.42, 0.60),
      bet(1, 'A2', 1.42, 0.60), // same matchId
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.modere,
      pool: pool,
    );
    expect(combos, isEmpty);
  });

  test('filters out selections not in the requested risk tier', () {
    final pool = [
      bet(1, 'A', 1.42, 0.40), // risqué, excluded
      bet(2, 'B', 1.42, 0.40),
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.modere,
      pool: pool,
    );
    expect(combos, isEmpty);
  });

  test('sorts by combo probability descending and caps results', () {
    final pool = [
      bet(1, 'A', 1.40, 0.70),
      bet(2, 'B', 1.45, 0.69),
      bet(3, 'C', 1.42, 0.68),
      bet(4, 'D', 1.43, 0.67),
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.modere,
      pool: pool,
      maxResults: 2,
    );
    expect(combos.length, 2);
    expect(combos[0].probability, greaterThanOrEqualTo(combos[1].probability));
  });
}
