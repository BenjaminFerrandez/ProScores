import '../config/constants.dart';
import '../models/combo.dart';
import '../models/combo_sort.dart';
import '../models/market.dart';
import '../models/risk_level.dart';
import '../models/selection.dart';

class CandidateBet {
  final int matchId;
  final String matchLabel;

  /// Which market this selection belongs to. A combo may use several legs from
  /// the same match, but never two from the same market *family* (their
  /// outcomes could contradict, e.g. a 1X2 result and a handicap).
  final MarketType market;
  final Selection selection;
  const CandidateBet({
    required this.matchId,
    required this.matchLabel,
    required this.market,
    required this.selection,
  });

  /// Uniqueness key: one leg allowed per (match, market family).
  (int, MarketFamily) get slot => (matchId, market.family);
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
  /// target multiplier (target / stake). When [risk] is null, proposals are
  /// generated across every risk band (low/medium/high odds) and merged;
  /// otherwise only the chosen band is used. Results are ordered by [sort].
  static List<Combo> generate({
    required double stake,
    required double target,
    RiskLevel? risk,
    required List<CandidateBet> pool,
    ComboSort sort = ComboSort.probabilityDesc,
    double tolerance = kComboTolerance,
    int maxLegs = kMaxComboLegs,
    int maxResults = kComboCount,
  }) {
    if (stake <= 0 || target <= stake) return [];

    final bands = risk != null
        ? [risk]
        : const [RiskLevel.peuRisque, RiskLevel.modere, RiskLevel.risque];

    final merged = <Combo>[];
    for (final band in bands) {
      for (final combo in _generateForBand(
        stake: stake,
        target: target,
        risk: band,
        pool: pool,
        tolerance: tolerance,
        maxLegs: maxLegs,
        maxResults: maxResults,
      )) {
        // Dedupe identical leg-sets that may appear across bands.
        final slots =
            combo.legs.map((l) => (l.matchId, l.market.family)).toSet();
        final dup = merged.any((r) =>
            r.legs.length == slots.length &&
            r.legs.every((l) => slots.contains((l.matchId, l.market.family))));
        if (!dup) merged.add(combo);
      }
    }

    _sort(merged, sort);
    return merged;
  }

  static void _sort(List<Combo> combos, ComboSort sort) {
    switch (sort) {
      case ComboSort.probabilityDesc:
        combos.sort((a, b) => b.probability.compareTo(a.probability));
      case ComboSort.probabilityAsc:
        combos.sort((a, b) => a.probability.compareTo(b.probability));
      case ComboSort.payoutDesc:
        combos.sort((a, b) => b.potentialWin.compareTo(a.potentialWin));
    }
  }

  static List<Combo> _generateForBand({
    required double stake,
    required double target,
    required RiskLevel risk,
    required List<CandidateBet> pool,
    required double tolerance,
    required int maxLegs,
    required int maxResults,
  }) {
    final multiplier = target / stake;
    final low = multiplier * (1 - tolerance);
    final high = multiplier * (1 + tolerance);
    final (bandLow, bandHigh) = oddsBandFor(risk);

    // Keep, per (match, market family), the single in-band selection with the
    // best probability. This lets a combo mix independent markets of the same
    // match (e.g. result + Over 1.5) while never combining two legs that could
    // contradict (e.g. 1X2 result + handicap, or Over + Under).
    final bySlot = <(int, MarketFamily), CandidateBet>{};
    for (final b in pool) {
      final o = b.selection.odd;
      if (o < bandLow || o > bandHigh) continue;
      final cur = bySlot[b.slot];
      if (cur == null ||
          b.selection.adjustedProbability >
              cur.selection.adjustedProbability) {
        bySlot[b.slot] = b;
      }
    }
    final candidates = bySlot.values.toList()
      ..sort((a, b) => a.selection.odd.compareTo(b.selection.odd));

    final results = <Combo>[];
    // Try anchoring a proposal on each candidate so we surface a few distinct
    // combos rather than the same one repeatedly.
    for (var start = 0;
        start < candidates.length && results.length < maxResults;
        start++) {
      final legs = _build(candidates, start, low, high, multiplier, maxLegs);
      if (legs == null) continue;
      final slots = legs.map((b) => b.slot).toSet();
      final isDuplicate = results.any((r) =>
          r.legs.length == slots.length &&
          r.legs.every((l) => slots.contains((l.matchId, l.market.family))));
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
                market: b.market,
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

  /// Greedily stacks legs (one per match+market slot) starting from
  /// [startIndex] until the running product of odds lands within [low, high].
  /// Returns null if the range can't be reached without overshooting [high].
  static List<CandidateBet>? _build(
    List<CandidateBet> candidates,
    int startIndex,
    double low,
    double high,
    double target,
    int maxLegs,
  ) {
    final chosen = <CandidateBet>[candidates[startIndex]];
    final usedSlots = <(int, MarketFamily)>{candidates[startIndex].slot};
    var product = candidates[startIndex].selection.odd;
    if (product > high) return null;
    if (product >= low) return chosen;

    while (chosen.length < maxLegs) {
      CandidateBet? finisher; // a leg that lands the product inside [low, high]
      var finisherProduct = 0.0;
      CandidateBet? advancer; // largest step that still stays <= high
      var advancerProduct = 0.0;

      for (final c in candidates) {
        if (usedSlots.contains(c.slot)) continue;
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
      usedSlots.add(advancer.slot);
      product = advancerProduct;
    }
    return null; // hit the leg cap before reaching the range
  }
}
