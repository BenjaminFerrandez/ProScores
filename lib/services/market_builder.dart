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
      selections.add(Selection(
        label: labels[i],
        odd: bookmakerOdds[i],
        adjustedProbability: p,
        risk: RiskClassifier.classify(p),
      ));
    }
    return Market(type: MarketType.resultat1x2, selections: selections);
  }
}
