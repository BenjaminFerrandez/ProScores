import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/services/risk_classifier.dart';

void main() {
  test('>= 0.70 is peu risqué', () {
    expect(RiskClassifier.classify(0.70), RiskLevel.peuRisque);
    expect(RiskClassifier.classify(0.91), RiskLevel.peuRisque);
  });
  test('0.50–0.70 is modéré', () {
    expect(RiskClassifier.classify(0.50), RiskLevel.modere);
    expect(RiskClassifier.classify(0.699), RiskLevel.modere);
  });
  test('0.30–0.50 is risqué', () {
    expect(RiskClassifier.classify(0.30), RiskLevel.risque);
    expect(RiskClassifier.classify(0.499), RiskLevel.risque);
  });
  test('< 0.30 is très risqué', () {
    expect(RiskClassifier.classify(0.29), RiskLevel.tresRisque);
    expect(RiskClassifier.classify(0.0), RiskLevel.tresRisque);
  });
}
