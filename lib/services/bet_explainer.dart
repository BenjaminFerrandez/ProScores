import '../models/combo.dart';
import '../models/market.dart';

/// Turns a bet leg into a short, plain-French sentence explaining what has to
/// happen for it to win.
class BetExplainer {
  static String explain(ComboLeg leg) {
    final parts = leg.matchLabel.split(' - ');
    final home = parts.isNotEmpty ? parts.first.trim() : 'Domicile';
    final away = parts.length > 1 ? parts.last.trim() : 'Extérieur';
    final label = leg.selection.label.trim();

    switch (leg.market) {
      case MarketType.resultat1x2:
        return switch (label) {
          '1' => '$home gagne le match.',
          'N' => 'Le match se termine sur un nul.',
          '2' => '$away gagne le match.',
          _ => 'Issue : $label.',
        };
      case MarketType.totalButs:
        final line = _firstNumber(label);
        return label.startsWith('-')
            ? 'Moins de $line buts dans le match.'
            : 'Plus de $line buts dans le match.';
      case MarketType.handicap:
        return _explainHandicap(label, home, away);
    }
  }

  static String _explainHandicap(String label, String home, String away) {
    // Labels look like "1 (-1.5)" / "2 (+1.5)": team index, then the line in ().
    final isHome = label.startsWith('1');
    final team = isHome ? home : away;
    final inner =
        RegExp(r'\(([-+]?\d+(?:\.\d+)?)\)').firstMatch(label)?.group(1);
    final h = double.tryParse(inner ?? '') ?? 0; // e.g. -1.5 or +0.5
    if (h < 0) {
      final margin = (-h).ceil(); // -1.5 -> 2, -0.5 -> 1
      return margin <= 1
          ? '$team gagne le match.'
          : '$team gagne avec au moins $margin buts d\'écart.';
    }
    final cushion = h.floor(); // +0.5 -> 0, +1.5 -> 1
    return cushion == 0
        ? '$team gagne ou fait match nul.'
        : '$team gagne, fait nul, ou perd par $cushion but${cushion > 1 ? 's' : ''} maximum.';
  }

  /// First unsigned number found (e.g. "+2.5" -> "2.5").
  static String _firstNumber(String s) {
    final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(s);
    return m?.group(0) ?? s;
  }
}
