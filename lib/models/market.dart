import 'selection.dart';

enum MarketType {
  resultat1x2,
  totalButs,
  handicap,
  btts,
  overUnder25,
  doubleChance,
}

extension MarketTypeLabel on MarketType {
  String get label => switch (this) {
        MarketType.resultat1x2 => 'Vainqueur du match',
        MarketType.totalButs => 'Plus / moins de buts',
        MarketType.handicap => 'Handicap',
        MarketType.btts => 'Les deux équipes marquent',
        MarketType.overUnder25 => 'Plus / moins de 2.5 buts',
        MarketType.doubleChance => 'Double chance',
      };
}

/// Groups markets that describe the same underlying question. Outcomes from
/// two markets in the same family can contradict each other (e.g. a 1X2 "home
/// win" and a handicap "away +0.5"), so a combo must use at most one leg per
/// family per match.
enum MarketFamily { result, goals, bothScore }

extension MarketTypeFamily on MarketType {
  MarketFamily get family => switch (this) {
        // Everything about who wins the match.
        MarketType.resultat1x2 ||
        MarketType.handicap ||
        MarketType.doubleChance =>
          MarketFamily.result,
        // Everything about the number of goals.
        MarketType.totalButs || MarketType.overUnder25 => MarketFamily.goals,
        MarketType.btts => MarketFamily.bothScore,
      };
}

class Market {
  final MarketType type;
  final List<Selection> selections;
  const Market({required this.type, required this.selections});
}
