import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/combo.dart';
import 'package:proscores/models/market.dart';
import 'package:proscores/models/selection.dart';
import 'package:proscores/services/bet_explainer.dart';

ComboLeg leg(MarketType market, String label) => ComboLeg(
      matchId: 1,
      matchLabel: 'Cape Verde - Saudi Arabia',
      market: market,
      selection: Selection(label: label, odd: 1.5, adjustedProbability: 0.5),
    );

void main() {
  test('1X2 outcomes', () {
    expect(BetExplainer.explain(leg(MarketType.resultat1x2, '1')),
        'Cape Verde gagne le match.');
    expect(BetExplainer.explain(leg(MarketType.resultat1x2, 'N')),
        'Le match se termine sur un nul.');
    expect(BetExplainer.explain(leg(MarketType.resultat1x2, '2')),
        'Saudi Arabia gagne le match.');
  });

  test('totals over / under', () {
    expect(BetExplainer.explain(leg(MarketType.totalButs, '+2.5')),
        'Plus de 2.5 buts dans le match.');
    expect(BetExplainer.explain(leg(MarketType.totalButs, '-1.5')),
        'Moins de 1.5 buts dans le match.');
  });

  test('handicap home and away lines', () {
    // home -1.5 -> win by 2+
    expect(BetExplainer.explain(leg(MarketType.handicap, '1 (-1.5)')),
        'Cape Verde gagne avec au moins 2 buts d\'écart.');
    // away +0.5 -> win or draw
    expect(BetExplainer.explain(leg(MarketType.handicap, '2 (+0.5)')),
        'Saudi Arabia gagne ou fait match nul.');
    // home -0.5 -> just win
    expect(BetExplainer.explain(leg(MarketType.handicap, '1 (-0.5)')),
        'Cape Verde gagne le match.');
  });
}
