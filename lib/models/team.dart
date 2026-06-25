class Team {
  final int id;

  /// Display name (may be localized, e.g. French).
  final String name;

  /// Original/English name used for external lookups (API-Football search).
  /// Falls back to [name] when not provided.
  final String? searchName;
  final String? flag;
  const Team(
      {required this.id, required this.name, this.searchName, this.flag});

  String get lookupName => searchName ?? name;
}
