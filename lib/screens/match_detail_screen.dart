import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/market.dart';
import '../models/risk_level.dart';
import '../providers/match_detail_provider.dart';
import '../utils/team_flags.dart';
import '../widgets/error_retry.dart';
import '../widgets/probability_bar.dart';
import '../widgets/responsible_gaming_note.dart';
import 'match_stats_screen.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.fixtureId});
  final int fixtureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(matchDetailProvider(fixtureId));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: SquareIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop()),
          ),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
            message: 'Impossible de charger le match.\n$e',
            onRetry: () => ref.invalidate(matchDetailProvider(fixtureId))),
        data: (match) => ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(match.competition,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(
                DateFormat("EEEE d MMM · HH:mm", 'fr_FR')
                    .format(match.kickoff.toLocal()),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(match.home.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text('VS', style: TextStyle(color: AppColors.muted)),
                Text(match.away.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            if (match.markets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Cotes indisponibles pour ce match.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted)),
              ),
            ...match.markets.map((m) => _MarketCard(m)),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MatchStatsScreen(fixtureId: fixtureId))),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal),
                  minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.bar_chart_rounded, size: 20),
              label: const Text('Stats & historique des équipes',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const ResponsibleGamingNote(),
          ],
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard(this.market);
  final Market market;

  @override
  Widget build(BuildContext context) {
    final topRisk = market.selections.first.risk;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(market.type.label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (topRisk != null) _RiskTag(topRisk),
            ],
          ),
          const SizedBox(height: 10),
          ...market.selections.map((s) {
            final value = s.valueEdge != null &&
                s.valueEdge! >= kValueEdgeThreshold;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                      width: 60,
                      child: Text(s.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12))),
                  Expanded(
                      child: ProbabilityBar(
                          probability: s.adjustedProbability,
                          oddLabel: s.odd.toStringAsFixed(2))),
                  if (value) ...[
                    const SizedBox(width: 8),
                    _ValueTag(s.valueEdge!),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Highlights a selection priced above the market consensus (a value bet).
class _ValueTag extends StatelessWidget {
  const _ValueTag(this.edge);
  final double edge;
  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF5FE3B6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color)),
      child: Text('★ +${(edge * 100).round()}%',
          style: const TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _RiskTag extends StatelessWidget {
  const _RiskTag(this.risk);
  final RiskLevel risk;
  @override
  Widget build(BuildContext context) {
    final color = switch (risk) {
      RiskLevel.peuRisque => const Color(0xFF5FE3B6),
      RiskLevel.modere => const Color(0xFFE3D65F),
      RiskLevel.risque => const Color(0xFFE39A5F),
      RiskLevel.tresRisque => const Color(0xFFE35F5F),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18)),
      child: Text(risk.label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}

class _HeaderTeam extends StatelessWidget {
  const _HeaderTeam({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          TeamFlag(name, height: 40),
          const SizedBox(height: 8),
          Text(name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}
