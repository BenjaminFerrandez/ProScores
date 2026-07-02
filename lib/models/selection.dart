import 'risk_level.dart';

class Selection {
  final String label;
  final double odd;
  final double adjustedProbability;
  final RiskLevel? risk;

  /// Expected-value edge vs the market consensus: `odd * consensusProb - 1`.
  /// Positive = the offered price beats the market (a "value bet"). Null when
  /// no consensus is available.
  final double? valueEdge;

  const Selection({
    required this.label,
    required this.odd,
    required this.adjustedProbability,
    this.risk,
    this.valueEdge,
  });

  bool get isValue => valueEdge != null && valueEdge! > 0;
}
