import '../models/market.dart';
import '../models/selection.dart';
import 'probability_service.dart';
import 'risk_classifier.dart';

class MarketBuilder {
  static Market build1x2({
    required List<double> bookmakerOdds,
    List<double>? consensus,
  }) {
    final implied = ProbabilityService.normalizeImplied(bookmakerOdds);
    final labels = ['1', 'N', '2'];
    final selections = <Selection>[];
    for (var i = 0; i < 3; i++) {
      final p = implied[i];
      // Value vs the market consensus: odd * consensusProb - 1.
      final edge = consensus != null && consensus.length == 3
          ? bookmakerOdds[i] * consensus[i] - 1
          : null;
      selections.add(Selection(
        label: labels[i],
        odd: bookmakerOdds[i],
        adjustedProbability: p,
        risk: RiskClassifier.classify(p),
        valueEdge: edge,
      ));
    }
    return Market(type: MarketType.resultat1x2, selections: selections);
  }

  static Market buildTotals({
    required double point,
    required double overOdd,
    required double underOdd,
  }) {
    final probs = ProbabilityService.normalizeImplied([overOdd, underOdd]);
    final line = _formatPoint(point);
    return Market(type: MarketType.totalButs, selections: [
      Selection(
          label: '+$line',
          odd: overOdd,
          adjustedProbability: probs[0],
          risk: RiskClassifier.classify(probs[0])),
      Selection(
          label: '-$line',
          odd: underOdd,
          adjustedProbability: probs[1],
          risk: RiskClassifier.classify(probs[1])),
    ]);
  }

  static Market buildSpreads({
    required double homePoint,
    required double homeOdd,
    required double awayPoint,
    required double awayOdd,
  }) {
    final probs = ProbabilityService.normalizeImplied([homeOdd, awayOdd]);
    return Market(type: MarketType.handicap, selections: [
      Selection(
          label: '1 (${_signed(homePoint)})',
          odd: homeOdd,
          adjustedProbability: probs[0],
          risk: RiskClassifier.classify(probs[0])),
      Selection(
          label: '2 (${_signed(awayPoint)})',
          odd: awayOdd,
          adjustedProbability: probs[1],
          risk: RiskClassifier.classify(probs[1])),
    ]);
  }

  static String _formatPoint(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toString();

  static String _signed(double p) =>
      '${p > 0 ? '+' : ''}${_formatPoint(p)}';
}
