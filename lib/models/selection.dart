import 'risk_level.dart';

class Selection {
  final String label;
  final double odd;
  final double adjustedProbability;
  final RiskLevel? risk;
  const Selection({
    required this.label,
    required this.odd,
    required this.adjustedProbability,
    this.risk,
  });

  Selection copyWith({RiskLevel? risk}) => Selection(
        label: label,
        odd: odd,
        adjustedProbability: adjustedProbability,
        risk: risk ?? this.risk,
      );
}
