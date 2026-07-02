import 'package:flutter_test/flutter_test.dart';
import 'package:proscores/models/risk_level.dart';
import 'package:proscores/models/selection.dart';
import 'package:proscores/models/market.dart';
import 'package:proscores/models/combo.dart';

void main() {
  test('RiskLevel labels are French', () {
    expect(RiskLevel.peuRisque.label, 'Peu risqué');
    expect(RiskLevel.modere.label, 'Modéré');
  });

  test('MarketType labels are French', () {
    expect(MarketType.resultat1x2.label, 'Vainqueur du match');
    expect(MarketType.totalButs.label, 'Plus / moins de buts');
    expect(MarketType.handicap.label, 'Handicap');
  });

  test('Selection stores odd and probability', () {
    const s = Selection(label: 'France', odd: 2.10, adjustedProbability: 0.48);
    expect(s.odd, 2.10);
    expect(s.adjustedProbability, 0.48);
  });

  test('Combo computes nothing itself but holds totals', () {
    const leg = ComboLeg(
      matchId: 1,
      matchLabel: 'France - Brésil',
      market: MarketType.resultat1x2,
      selection:
          Selection(label: 'France', odd: 2.1, adjustedProbability: 0.48),
    );
    const c = Combo(
        legs: [leg], totalOdds: 2.1, probability: 0.48, potentialWin: 21.0);
    expect(c.legs.single.matchLabel, 'France - Brésil');
    expect(c.potentialWin, 21.0);
  });
}
