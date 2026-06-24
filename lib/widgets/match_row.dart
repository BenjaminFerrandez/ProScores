import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import '../utils/team_flags.dart';
import 'time_chip.dart';

/// Compact upcoming-match row: flag · team · time chip · team · flag.
class MatchRow extends StatelessWidget {
  const MatchRow({super.key, required this.match, required this.onTap});
  final MatchFixture match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(match.kickoff.toLocal());
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        color: AppColors.card,
        child: Row(
          children: [
            TeamFlag(match.home.name, height: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(match.home.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TimeChip(time),
            ),
            Expanded(
              child: Text(match.away.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            TeamFlag(match.away.name, height: 26),
          ],
        ),
      ),
    );
  }
}
