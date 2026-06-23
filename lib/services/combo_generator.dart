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
  static List<Combo> generate({
    required double stake,
    required double target,
    required RiskLevel risk,
    required List<CandidateBet> pool,
    double tolerance = kComboTolerance,
    int maxLegs = kMaxLegs,
    int maxResults = kComboCount,
  }) {
    if (stake <= 0) return [];
    final multiplier = target / stake;
    final low = multiplier * (1 - tolerance);
    final high = multiplier * (1 + tolerance);

    final filtered =
        pool.where((b) => b.selection.risk == risk).toList(growable: false);

    final results = <Combo>[];
    // Enumerate combinations of size 2..maxLegs.
    for (var size = 2; size <= maxLegs; size++) {
      _combinations(filtered, size, (combo) {
        // reject two legs on the same match
        final matchIds = combo.map((b) => b.matchId).toSet();
        if (matchIds.length != combo.length) return;
        final totalOdds =
            combo.fold<double>(1.0, (acc, b) => acc * b.selection.odd);
        if (totalOdds < low || totalOdds > high) return;
        final probability = combo.fold<double>(
            1.0, (acc, b) => acc * b.selection.adjustedProbability);
        results.add(Combo(
          legs: combo
              .map((b) => ComboLeg(
                  matchId: b.matchId,
                  matchLabel: b.matchLabel,
                  selection: b.selection))
              .toList(),
          totalOdds: totalOdds,
          probability: probability,
          potentialWin: stake * totalOdds,
        ));
      });
    }

    results.sort((a, b) => b.probability.compareTo(a.probability));
    return results.take(maxResults).toList();
  }

  /// Calls [emit] with every size-[k] combination of [items].
  static void _combinations<T>(
    List<T> items,
    int k,
    void Function(List<T>) emit,
  ) {
    final n = items.length;
    if (k > n) return;
    final indices = List<int>.generate(k, (i) => i);
    while (true) {
      emit([for (final i in indices) items[i]]);
      var i = k - 1;
      while (i >= 0 && indices[i] == n - k + i) {
        i--;
      }
      if (i < 0) break;
      indices[i]++;
      for (var j = i + 1; j < k; j++) {
        indices[j] = indices[j - 1] + 1;
      }
    }
  }
}
