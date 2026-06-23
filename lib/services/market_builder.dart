import '../models/market.dart';
import '../models/prediction.dart';
import '../models/selection.dart';
import 'probability_service.dart';
import 'risk_classifier.dart';

class MarketBuilder {
  /// Builds the 1X2 market by blending normalized bookmaker odds with the
  /// model prediction. [bookmakerOdds] is ordered [home, draw, away].
  static Market build1x2({
    required List<double> bookmakerOdds,
    required Prediction prediction,
  }) {
    final implied = ProbabilityService.normalizeImplied(bookmakerOdds);
    final modelProbs = [
      prediction.homeProb,
      prediction.drawProb,
      prediction.awayProb,
    ];
    final labels = ['1', 'N', '2'];
    final selections = <Selection>[];
    for (var i = 0; i < 3; i++) {
      final p = ProbabilityService.blend(implied[i], modelProbs[i]);
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
