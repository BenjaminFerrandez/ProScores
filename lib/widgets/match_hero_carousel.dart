import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/match_fixture.dart';
import 'team_crest.dart';

/// Swipeable hero carousel featuring the next few upcoming matches, with a
/// dot indicator. Tapping a slide invokes [onTapMatch].
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
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _HeroCard(
              match: items[i],
              onTap: () => widget.onTapMatch(items[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < items.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 7,
                height: 7,
                color: i == _index ? AppColors.teal : AppColors.muted,
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.match, required this.onTap});
  final MatchFixture match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final when =
        DateFormat("EEE d MMM · HH:mm", 'fr_FR').format(match.kickoff.toLocal());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF063D2E), Color(0xFF049F7C)],
          ),
        ),
        child: Column(
          children: [
            Text(match.competition.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.2)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Side(name: match.home.name),
                const Text('VS',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                _Side(name: match.away.name),
              ],
            ),
            const Spacer(),
            Text(when,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
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
                  fontSize: 13)),
        ],
      ),
    );
  }
}
