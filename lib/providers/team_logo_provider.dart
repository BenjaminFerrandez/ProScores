import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

/// Resolves a national team's crest/logo URL by name (cached per session by
/// Riverpod). Returns null when unknown or on error.
final teamLogoProvider =
    FutureProvider.family<String?, String>((ref, teamName) async {
  final repo = ref.watch(footballRepositoryProvider);
  try {
    return await repo.nationalTeamLogo(teamName);
  } catch (_) {
    return null;
  }
});
