import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../config/assets.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import 'team_crest.dart';
import 'time_chip.dart';

/// Swipeable hero carousel featuring the next few upcoming matches, on a dark
/// card with teal corner triangles and SVG dot indicators.
class MatchHeroCarousel extends StatefulWidget {
  const MatchHeroCarousel({
    super.key,
    required this.matches,
    required this.onTapMatch,
  });
  final List<MatchFixture> matches;
  final void Function(MatchFixture) onTapMatch;

  @override
  State<MatchHeroCarousel> createState() => _MatchHeroCarouselState();
}

class _MatchHeroCarouselState extends State<MatchHeroCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.matches.take(4).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 240,
      color: AppColors.card,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Corner triangles, sticking slightly out of the card.
          Positioned(
            top: -9,
            left: -9,
            child: RotatedBox(
              quarterTurns: 2,
              child: SvgPicture.asset(Assets.triangleTopMatch, width: 90),
            ),
          ),
          Positioned(
            bottom: -9,
            right: -9,
            child: SvgPicture.asset(Assets.triangleTopMatch, width: 90),
          ),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: items.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => widget.onTapMatch(items[i]),
                    behavior: HitTestBehavior.opaque,
                    child: _HeroContent(match: items[i]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SvgPicture.asset(
                          i == _index
                              ? Assets.carouselDot
                              : Assets.carouselDotEmpty,
                          width: 9,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.match});
  final MatchFixture match;

  @override
  Widget build(BuildContext context) {
    final when =
        DateFormat("EEE d MMM · HH:mm", 'fr_FR').format(match.kickoff.toLocal());
    final time = DateFormat('HH:mm').format(match.kickoff.toLocal());
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          Text(match.competition.toUpperCase(),
              style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1.2)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Side(name: match.home.name)),
              TimeChip(time, height: 34),
              Expanded(child: _Side(name: match.away.name)),
            ],
          ),
          const Spacer(),
          Text(when,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamCrest(name, size: 48),
        const SizedBox(height: 8),
        Text(name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    );
  }
}
