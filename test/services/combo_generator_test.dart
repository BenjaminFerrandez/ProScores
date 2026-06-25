import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/combo_sort.dart';
import 'package:proscores/models/market.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/models/selection.dart';
import 'package:proscores/services/combo_generator.dart';

CandidateBet bet(int matchId, String label, double odd, double prob,
        {MarketType market = MarketType.resultat1x2}) =>
    CandidateBet(
      matchId: matchId,
      matchLabel: 'match$matchId',
      market: market,
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

  test('reaches a very large target (10€ -> 500€) by stacking many legs', () {
    // ×50 with low odds (~1.20) needs ~21 legs — must not be capped too low.
    final pool = [for (var i = 1; i <= 25; i++) bet(i, '1', 1.20, 0.85)];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 500,
      risk: RiskLevel.peuRisque,
      pool: pool,
    );
    expect(combos, isNotEmpty);
    expect(combos.first.totalOdds, greaterThanOrEqualTo(45.0));
    expect(combos.first.totalOdds, lessThanOrEqualTo(55.0));
    expect(combos.first.legs.length, greaterThan(15));
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

  test('never combines two outcomes of the same market (same match)', () {
    // Two selections of the SAME market on the same match -> can't combine.
    final pool = [
      bet(1, 'A', 1.42, 0.60),
      bet(1, 'A2', 1.42, 0.60), // same match + same market
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: RiskLevel.peuRisque,
      pool: pool,
    );
    expect(combos, isEmpty);
  });

  test('allows independent markets of the same match in one combo', () {
    // e.g. Norway-France: "France win" (1X2) + "Over 1.5" (totals), same match.
    final pool = [
      bet(1, '2', 1.40, 0.60, market: MarketType.resultat1x2),
      bet(1, '+1.5', 1.45, 0.58, market: MarketType.totalButs),
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 20, // ×2 ~ 1.40*1.45 = 2.03
      risk: RiskLevel.peuRisque,
      pool: pool,
    );
    expect(combos, isNotEmpty);
    expect(combos.first.legs.length, 2);
    // both legs come from the same match...
    expect(combos.first.legs.every((l) => l.matchId == 1), isTrue);
    // ...but from different markets.
    expect(combos.first.legs.map((l) => l.market).toSet().length, 2);
  });

  test('never combines contradictory result markets (1X2 + handicap)', () {
    // The exact bug: "Cape Verde win" (1X2) + "Saudi +0.5" (handicap) can never
    // both be true. Both are in the result family -> must not be combined.
    final pool = [
      bet(1, '1', 2.40, 0.45, market: MarketType.resultat1x2),
      bet(1, '2 (+0.5)', 1.56, 0.62, market: MarketType.handicap),
    ];
    final combos = ComboGenerator.generate(
      stake: 10,
      target: 37, // ×3.74 — only reachable by combining the two legs
      risk: null,
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

  test('null risk searches across all bands', () {
    // target ×2. A low-odds combo (1.40*1.45) and a single high-odds leg (2.0)
    // both reach it, in different bands.
    final pool = [
      bet(1, 'low1', 1.40, 0.60),
      bet(2, 'low2', 1.45, 0.58),
      bet(3, 'high', 2.00, 0.50), // risqué band, single-leg ×2
    ];
    final all = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: null, // no filter
      pool: pool,
    );
    // We should get proposals from more than one band (low-odds 2-leg + the
    // single high-odds leg).
    expect(all.length, greaterThanOrEqualTo(2));
    expect(all.any((c) => c.legs.length == 1 && c.legs.first.selection.odd == 2.0),
        isTrue);
    expect(all.any((c) => c.legs.length == 2), isTrue);
  });

  test('sort option orders the results', () {
    final pool = [
      bet(1, 'low1', 1.40, 0.60),
      bet(2, 'low2', 1.45, 0.58),
      bet(3, 'high', 2.00, 0.50),
    ];
    final byPayout = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: null,
      pool: pool,
      sort: ComboSort.payoutDesc,
    );
    for (var i = 1; i < byPayout.length; i++) {
      expect(byPayout[i - 1].potentialWin,
          greaterThanOrEqualTo(byPayout[i].potentialWin));
    }
    final byProbAsc = ComboGenerator.generate(
      stake: 10,
      target: 20,
      risk: null,
      pool: pool,
      sort: ComboSort.probabilityAsc,
    );
    for (var i = 1; i < byProbAsc.length; i++) {
      expect(byProbAsc[i - 1].probability,
          lessThanOrEqualTo(byProbAsc[i].probability));
    }
  });
}
