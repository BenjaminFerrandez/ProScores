import '../config/constants.dart';
import '../models/combo.dart';
import '../models/risk_level.dart';
import '../models/selection.dart';

class CandidateBet {
  final int matchId;
  final String matchLabel;
  final Selection selection;
  const CandidateBet({
    required this.matchId,
    required this.matchLabel,
    required this.selection,
  });
}

class ComboGenerator {
  /// The inclusive band of *individual* odds allowed for a leg at each risk
  /// level. Faible = low odds, risqué = high odds.
  static (double, double) oddsBandFor(RiskLevel risk) => switch (risk) {
        RiskLevel.peuRisque => (1.01, kLowRiskMaxOdd),
        RiskLevel.modere => (kLowRiskMaxOdd, kModerateMaxOdd),
        RiskLevel.risque => (kModerateMaxOdd, double.infinity),
        RiskLevel.tresRisque => (kModerateMaxOdd, double.infinity),
      };

  /// Builds combos whose product of odds lands within [tolerance] of the
  /// target multiplier (target / stake), using only legs whose individual
  /// odd falls in the requested risk's band. Legs are stacked as deep as
  /// needed (up to [maxLegs]) so that low odds can still reach a big target.
  static List<Combo> generate({
    required double stake,
    required double target,
    required RiskLevel risk,
    required List<CandidateBet> pool,
    double tolerance = kComboTolerance,
    int maxLegs = kMaxComboLegs,
    int maxResults = kComboCount,
  }) {
    if (stake <= 0 || target <= stake) return [];
    final multiplier = target / stake;
    final low = multiplier * (1 - tolerance);
    final high = multiplier * (1 + tolerance);
    final (bandLow, bandHigh) = oddsBandFor(risk);

    // Keep, per match, the single in-band selection with the best probability
    // (a combo can never use two legs from the same match).
    final byMatch = <int, CandidateBet>{};
    for (final b in pool) {
      final o = b.selection.odd;
      if (o < bandLow || o > bandHigh) continue;
      final cur = byMatch[b.matchId];
      if (cur == null ||
          b.selection.adjustedProbability >
              cur.selection.adjustedProbability) {
        byMatch[b.matchId] = b;
      }
    }
    final candidates = byMatch.values.toList()
      ..sort((a, b) => a.selection.odd.compareTo(b.selection.odd));

    final results = <Combo>[];
    // Try anchoring a proposal on each candidate so we surface a few distinct
    // combos rather than the same one repeatedly.
    for (var start = 0;
        start < candidates.length && results.length < maxResults;
        start++) {
      final legs = _build(candidates, start, low, high, multiplier, maxLegs);
      if (legs == null) continue;
      final ids = legs.map((b) => b.matchId).toSet();
      final isDuplicate = results.any((r) =>
          r.legs.length == ids.length &&
          r.legs.every((l) => ids.contains(l.matchId)));
      if (isDuplicate) continue;

      final totalOdds =
          legs.fold<double>(1.0, (acc, b) => acc * b.selection.odd);
      final probability = legs.fold<double>(
          1.0, (acc, b) => acc * b.selection.adjustedProbability);
      results.add(Combo(
        legs: legs
            .map((b) => ComboLeg(
                matchId: b.matchId,
                matchLabel: b.matchLabel,
                selection: b.selection))
            .toList(),
        totalOdds: totalOdds,
        probability: probability,
        potentialWin: stake * totalOdds,
      ));
    }

    results.sort((a, b) => b.probability.compareTo(a.probability));
    return results.take(maxResults).toList();
  }

  /// Greedily stacks distinct-match legs starting from [startIndex] until the
  /// running product of odds lands within [low, high]. Returns null if the
  /// range can't be reached without overshooting [high].
  static List<CandidateBet>? _build(
    List<CandidateBet> candidates,
    int startIndex,
    double low,
    double high,
    double target,
    int maxLegs,
  ) {
    final chosen = <CandidateBet>[candidates[startIndex]];
    final usedMatches = <int>{candidates[startIndex].matchId};
    var product = candidates[startIndex].selection.odd;
    if (product > high) return null;
    if (product >= low) return chosen;

    while (chosen.length < maxLegs) {
      CandidateBet? finisher; // a leg that lands the product inside [low, high]
      var finisherProduct = 0.0;
      CandidateBet? advancer; // largest step that still stays <= high
      var advancerProduct = 0.0;

      for (final c in candidates) {
        if (usedMatches.contains(c.matchId)) continue;
        final p = product * c.selection.odd;
        if (p > high) continue;
        if (p >= low) {
          if (finisher == null ||
              (p - target).abs() < (finisherProduct - target).abs()) {
            finisher = c;
            finisherProduct = p;
          }
        } else if (p > advancerProduct) {
          advancer = c;
          advancerProduct = p;
        }
      }

      if (finisher != null) {
        chosen.add(finisher);
        return chosen;
      }
      if (advancer == null) return null; // can't get closer without overshoot
      chosen.add(advancer);
      usedMatches.add(advancer.matchId);
      product = advancerProduct;
    }
    return null; // hit the leg cap before reaching the range
  }
}
