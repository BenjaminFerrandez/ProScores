import 'selection.dart';

enum MarketType { resultat1x2, btts, overUnder25, doubleChance }

extension MarketTypeLabel on MarketType {
  String get label => switch (this) {
        MarketType.resultat1x2 => 'Vainqueur du match',
        MarketType.btts => 'Les deux équipes marquent',
        MarketType.overUnder25 => 'Plus / moins de 2.5 buts',
        MarketType.doubleChance => 'Double chance',
      };
}

class Market {
  final MarketType type;
  final List<Selection> selections;
  const Market({required this.type, required this.selections});
}
