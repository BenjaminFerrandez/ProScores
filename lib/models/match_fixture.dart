import 'market.dart';
import 'team.dart';

class MatchFixture {
  final int id;
  final String competition;
  final String? group;
  final DateTime kickoff;
  final Team home;
  final Team away;
  final List<Market> markets;
  const MatchFixture({
    required this.id,
    required this.competition,
    this.group,
    required this.kickoff,
    required this.home,
    required this.away,
    this.markets = const [],
  });

  String get label => '${home.name} - ${away.name}';

  MatchFixture copyWith({List<Market>? markets}) => MatchFixture(
        id: id,
        competition: competition,
        group: group,
        kickoff: kickoff,
        home: home,
        away: away,
        markets: markets ?? this.markets,
      );
}
