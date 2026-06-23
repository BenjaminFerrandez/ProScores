import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/market.dart';
import 'package:proscores/models/prediction.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/services/market_builder.dart';

void main() {
  test('build1x2 blends odds + prediction and tags risk', () {
    // implied from 2.0/4.0/4.0 -> 0.5/0.25/0.25 (already normalized)
    const pred = Prediction(homeProb: 0.5, drawProb: 0.25, awayProb: 0.25);
    final market = MarketBuilder.build1x2(
      bookmakerOdds: [2.0, 4.0, 4.0],
      prediction: pred,
    );
    expect(market.type, MarketType.resultat1x2);
    expect(market.selections, hasLength(3));
    // home: blend(0.5, 0.5) = 0.5 -> modéré
    expect(market.selections.first.adjustedProbability, closeTo(0.5, 1e-9));
    expect(market.selections.first.risk, RiskLevel.modere);
    expect(market.selections.first.odd, 2.0);
  });

  test('build1x2 without a prediction uses the implied probability only', () {
    // odds 1.8/3.6/5.14 -> implied 0.5556/0.2778/0.1946, sum 1.028
    // normalized home ~ 0.5405
    final market = MarketBuilder.build1x2(bookmakerOdds: [1.8, 3.6, 5.14]);
    final probs =
        market.selections.map((s) => s.adjustedProbability).toList();
    expect(probs.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
    expect(probs.first, closeTo(0.5405, 1e-3));
    expect(market.selections.first.risk, RiskLevel.modere);
  });
}
