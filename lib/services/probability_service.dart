class ProbabilityService {
  /// Implied probabilities normalized so the bookmaker margin is removed.
  static List<double> normalizeImplied(List<double> odds) {
    final implied = odds.map((o) => 1.0 / o).toList();
    final sum = implied.fold<double>(0, (a, b) => a + b);
    return implied.map((p) => p / sum).toList();
  }
}
