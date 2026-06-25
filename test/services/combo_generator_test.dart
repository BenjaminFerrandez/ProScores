import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/models/selection.dart';
import 'package:proscores/services/combo_generator.dart';

CandidateBet bet(int matchId, String label, double odd, double prob) =>
    CandidateBet(
      matchId: matchId,
      matchLabel: 'match$matchId',
      selection: Selection(label: label, odd: odd, adjustedProbability: prob),
    );

void main() {
  test('stacks many low-odds legs to reach a big target (×10 from faible)', () {
    // 10€ -> 100€ with only low odds (~1.20). Needs ~13 legs.
    final pool = [
      for (var i = 1; i <= 30; i++) bet(i, '1', 1.20, 0.80),
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 100,
      risk: RiskLevel.peuRisque,
      pool: pool,
    );
    expect(combos, isNotEmpty);
    // total odds within ±10% of ×10
    expect(combos.first.totalOdds, greaterThanOrEqualTo(9.0));
    expect(combos.first.totalOdds, lessThanOrEqualTo(11.0));
    // it really took several legs
    expect(combos.first.legs.length, greaterThan(5));
  });

  test('finds a combo near the target multiplier (faible)', () {
    // target ×2; low odds 1.40*1.45 = 2.03 within ±10%
    final pool = [
      bet(1, 'A', 1.40, 0.60),
      bet(2, 'B', 1.45, 0.58),
      bet(3, 'C', 5.00, 0.55), // out of the faible band
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.peuRisque,
      pool: pool,
    );
    expect(combos, isNotEmpty);
    expect(combos.first.totalOdds, closeTo(2.03, 0.01));
    expect(combos.first.potentialWin, closeTo(20.3, 0.1));
    expect(combos.first.probability, closeTo(0.60 * 0.58, 1e-9));
  });

  test('never uses two legs from the same match', () {
    // Two selections on the same match, target needs both -> impossible.
    final pool = [
      bet(1, 'A', 1.42, 0.60),
      bet(1, 'A2', 1.42, 0.60), // same matchId
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.peuRisque,
      pool: pool,
    );
    expect(combos, isEmpty);
  });

  test('filters out legs outside the requested risk band', () {
    // Odds 1.42 are "faible", so a "risqué" request finds nothing here.
    final pool = [
      bet(1, 'A', 1.42, 0.60),
      bet(2, 'B', 1.42, 0.60),
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 50,
      risk: RiskLevel.risque,
      pool: pool,
    );
    expect(combos, isEmpty);
  });

  test('returns nothing when target is not above the stake', () {
    final pool = [bet(1, 'A', 1.20, 0.80)];
    expect(
      ComboGenerator.generate(
          stake: 10, target: 10, risk: RiskLevel.peuRisque, pool: pool),
      isEmpty,
    );
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
      risk: RiskLevel.peuRisque,
      pool: pool,
      maxResults: 2,
    );
    expect(combos.length, lessThanOrEqualTo(2));
    if (combos.length == 2) {
      expect(
          combos[0].probability, greaterThanOrEqualTo(combos[1].probability));
    }
  });
}
