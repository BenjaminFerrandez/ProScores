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

  test('buildTotals labels the line and removes the margin', () {
    final market =
        MarketBuilder.buildTotals(point: 2.5, overOdd: 2.0, underOdd: 2.0);
    expect(market.type, MarketType.totalButs);
    expect(market.selections.map((s) => s.label).toList(), ['+2.5', '-2.5']);
    expect(market.selections.map((s) => s.odd).toList(), [2.0, 2.0]);
    // even odds -> 50/50 after normalization
    expect(market.selections.first.adjustedProbability, closeTo(0.5, 1e-9));
  });

  test('buildSpreads shows signed handicap lines for home and away', () {
    final market = MarketBuilder.buildSpreads(
        homePoint: -1.5, homeOdd: 1.9, awayPoint: 1.5, awayOdd: 1.95);
    expect(market.type, MarketType.handicap);
    expect(market.selections.first.label, '1 (-1.5)');
    expect(market.selections.last.label, '2 (+1.5)');
    final sum = market.selections
        .map((s) => s.adjustedProbability)
        .reduce((a, b) => a + b);
    expect(sum, closeTo(1.0, 1e-9));
  });
}
