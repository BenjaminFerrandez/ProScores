import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/team_logo_provider.dart';
import '../utils/team_flags.dart';

/// Displays a national team's crest/logo (from API-Football), gracefully
/// falling back to the country flag while loading or when unavailable.
class TeamCrest extends ConsumerWidget {
  const TeamCrest(this.teamName, {super.key, this.size = 44});
  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = ref.watch(teamLogoProvider(teamName));
    final fallback = TeamFlag(teamName, height: size * 0.72);
    return switch (logo) {
      AsyncData(:final value) when value != null => Image.network(
          value,
          height: size,
          width: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => fallback,
        ),
      _ => fallback,
    };
  }
}
