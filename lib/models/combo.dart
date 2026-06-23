import 'selection.dart';

class ComboLeg {
  final int matchId;
  final String matchLabel;
  final Selection selection;
  const ComboLeg({
    required this.matchId,
    required this.matchLabel,
    required this.selection,
  });
}

class Combo {
  final List<ComboLeg> legs;
  final double totalOdds;
  final double probability;
  final double potentialWin;
  const Combo({
    required this.legs,
    required this.totalOdds,
    required this.probability,
    required this.potentialWin,
  });
}
