import '../config/constants.dart';

class ProbabilityService {
  /// Implied probabilities normalized so the bookmaker margin is removed.
  static List<double> normalizeImplied(List<double> odds) {
    final implied = odds.map((o) => 1.0 / o).toList();
    final sum = implied.fold<double>(0, (a, b) => a + b);
    return implied.map((p) => p / sum).toList();
  }

  /// Weighted average of bookmaker and model probabilities.
  static double blend(
    double bookmakerProb,
    double modelProb, {
    double weightBookmaker = kBookmakerWeight,
  }) =>
      bookmakerProb * weightBookmaker + modelProb * (1 - weightBookmaker);
}
