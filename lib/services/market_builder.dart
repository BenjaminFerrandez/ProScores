import '../models/market.dart';
import '../models/prediction.dart';
import '../models/selection.dart';
import 'probability_service.dart';
import 'risk_classifier.dart';

class MarketBuilder {
  /// Builds the 1X2 market from normalized bookmaker odds, optionally blended
  /// with a model [prediction]. [bookmakerOdds] is ordered [home, draw, away].
  /// When [prediction] is null the displayed probability is the implied
  /// (margin-removed) bookmaker probability alone.
  static Market build1x2({
    required List<double> bookmakerOdds,
    Prediction? prediction,
    List<double>? consensus,
  }) {
    final implied = ProbabilityService.normalizeImplied(bookmakerOdds);
    final modelProbs = prediction == null
        ? null
        : [prediction.homeProb, prediction.drawProb, prediction.awayProb];
    final labels = ['1', 'N', '2'];
    final selections = <Selection>[];
    for (var i = 0; i < 3; i++) {
      final p = modelProbs == null
          ? implied[i]
          : ProbabilityService.blend(implied[i], modelProbs[i]);
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

  /// Builds the totals (over/under) market from a single bookmaker line.
  /// Probabilities are the margin-removed implied probabilities.
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

  /// Builds the handicap (spreads) market. Home is shown as "1", away as "2",
  /// each annotated with its handicap line.
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

  /// "2.5" -> "2.5", "3.0" -> "3".
  static String _formatPoint(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toString();

  /// Adds an explicit sign: 1.5 -> "+1.5", -1.5 -> "-1.5".
  static String _signed(double p) =>
      '${p > 0 ? '+' : ''}${_formatPoint(p)}';
}
