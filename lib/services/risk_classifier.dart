import '../models/risk_level.dart';

class RiskClassifier {
  static RiskLevel classify(double probability) {
    if (probability >= 0.70) return RiskLevel.peuRisque;
    if (probability >= 0.50) return RiskLevel.modere;
    if (probability >= 0.30) return RiskLevel.risque;
    return RiskLevel.tresRisque;
  }
}
