import 'market.dart';
import 'team.dart';

class MatchFixture {
  final int id;
  final String competition;
  final DateTime kickoff;
  final Team home;
  final Team away;
  final List<Market> markets;
  const MatchFixture({
    required this.id,
    required this.competition,
    required this.kickoff,
    required this.home,
    required this.away,
    this.markets = const [],
  });

  String get label => '${home.name} - ${away.name}';
}
