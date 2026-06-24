import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../config/assets.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import '../utils/team_flags.dart';
import 'time_chip.dart';

/// Compact upcoming-match row: flags + team names, a full-height wavy divider,
/// and the kickoff-time chip straddling the bottom edge of the card.
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
        margin: const EdgeInsets.only(bottom: 18),
        color: AppColors.card,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Full-height wavy divider, centered.
            Positioned.fill(
              child: Center(
                child: SvgPicture.asset(Assets.dividerSquiggle,
                    fit: BoxFit.fitHeight),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                  const SizedBox(width: 30),
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
            // Kickoff time straddling the bottom edge of the card.
            Positioned(
              left: 0,
              right: 0,
              bottom: -13,
              child: Center(child: TimeChip(time)),
            ),
          ],
        ),
      ),
    );
  }
}
