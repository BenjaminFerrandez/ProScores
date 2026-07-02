class H2HMatch {
  final DateTime date;
  final String homeName;
  final String awayName;
  final int? homeGoals;
  final int? awayGoals;
  const H2HMatch({
    required this.date,
    required this.homeName,
    required this.awayName,
    this.homeGoals,
    this.awayGoals,
  });
}

// A recent finished match, seen from that team's perspective (goalsFor is
// the team's own score, home or away).
class TeamResult {
  final DateTime date;
  final String opponent;
  final bool isHome;
  final int goalsFor;
  final int goalsAgainst;
  const TeamResult({
    required this.date,
    required this.opponent,
    required this.isHome,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  /// 'W', 'D' or 'L' from the team's point of view.
  String get outcome => goalsFor > goalsAgainst
      ? 'W'
      : goalsFor == goalsAgainst
          ? 'D'
          : 'L';
}

class SquadPlayer {
  final String name;
  final String? position; // Goalkeeper / Defender / Midfielder / Attacker
  final int? appearances;
  final int? goals;
  const SquadPlayer({
    required this.name,
    this.position,
    this.appearances,
    this.goals,
  });
}

class TeamDossier {
  final int teamId;
  final String name;
  final List<TeamResult> recentResults;
  final List<SquadPlayer> squad;
  const TeamDossier({
    required this.teamId,
    required this.name,
    this.recentResults = const [],
    this.squad = const [],
  });
}

class MatchStats {
  final TeamDossier home;
  final TeamDossier away;
  final List<H2HMatch> headToHead;
  const MatchStats({
    required this.home,
    required this.away,
    this.headToHead = const [],
  });
}
