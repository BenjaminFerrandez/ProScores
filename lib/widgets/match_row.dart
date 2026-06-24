import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../config/assets.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import '../utils/team_flags.dart';
import 'time_chip.dart';

/// Compact upcoming-match row: flag · team · time chip (over a full-height
/// wavy divider) · team · flag.
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
        color: AppColors.card,
        child: Stack(
          children: [
            // Full-height wavy divider, centered behind the time chip.
            Positioned.fill(
              child: Center(
                child: SvgPicture.asset(Assets.dividerSquiggle,
                    fit: BoxFit.fitHeight),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          ],
        ),
      ),
    );
  }
}
