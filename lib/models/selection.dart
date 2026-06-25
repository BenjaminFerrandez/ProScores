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

  /// True when the price offers a meaningful edge over the market consensus.
  bool get isValue => valueEdge != null && valueEdge! > 0;

  Selection copyWith({RiskLevel? risk}) => Selection(
        label: label,
        odd: odd,
        adjustedProbability: adjustedProbability,
        risk: risk ?? this.risk,
        valueEdge: valueEdge,
      );
}
