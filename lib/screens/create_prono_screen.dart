import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/assets.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/combo.dart';
import '../models/combo_sort.dart';
import '../models/market.dart';
import '../models/risk_level.dart';
import '../providers/combo_provider.dart';
import '../services/bet_explainer.dart';
import '../widgets/app_logo.dart';
import '../widgets/error_retry.dart';
import '../widgets/responsible_gaming_note.dart';
import '../widgets/wobble_button.dart';

class CreatePronoScreen extends ConsumerStatefulWidget {
  const CreatePronoScreen({super.key});
  @override
  ConsumerState<CreatePronoScreen> createState() => _CreatePronoScreenState();
}

class _CreatePronoScreenState extends ConsumerState<CreatePronoScreen> {
  final _stake = TextEditingController(text: '5');
  final _target = TextEditingController(text: '10');
  final Set<RiskLevel> _risks = {}; // empty = all
  final Set<String> _teams = {};
  ComboSort _sort = ComboSort.probabilityDesc;
  ComboRequest? _request;
  bool _filtersOpen = false;

  int get _activeFilterCount =>
      (_risks.isNotEmpty ? 1 : 0) + (_teams.isNotEmpty ? 1 : 0);

  @override
  void dispose() {
    _stake.dispose();
    _target.dispose();
    super.dispose();
  }

  double get _stakeVal => double.tryParse(_stake.text) ?? 0;
  double get _targetVal => double.tryParse(_target.text) ?? 0;
  double get _multiplier => _stakeVal > 0 ? _targetVal / _stakeVal : 0;
  bool get _valid => _stakeVal > 0 && _targetVal > _stakeVal;

  void _submit() {
    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('L\'objectif doit être supérieur à la mise.')));
      return;
    }
    setState(() {
      _request = ComboRequest(
        stake: _stakeVal,
        target: _targetVal,
        risks: {..._risks},
        teams: {..._teams},
        sort: _sort,
      );
    });
  }

  void _changeSort(ComboSort s) {
    setState(() {
      _sort = s;
      if (_request != null) _request = _request!.copyWith(sort: s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        centerTitle: true,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: SquareIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop()),
          ),
        ),
        title: const AppLogo(height: 34),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _StakeTargetBox(
            stake: _stake,
            target: _target,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text('${_multiplier.toStringAsFixed(_multiplier % 1 == 0 ? 0 : 1)}X',
                style: tabularNumberStyle(TextStyle(
                    color: AppColors.light,
                    fontWeight: FontWeight.w800,
                    fontSize: 22))),
          ),
          const SizedBox(height: 10),
          _RiskBar(multiplier: _multiplier),
          if (_targetVal > 0 && _stakeVal > 0 && _targetVal <= _stakeVal)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('L\'objectif de gain doit être supérieur à la mise.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFFE35F5F), fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 20),

          _FilterPanel(
            open: _filtersOpen,
            activeCount: _activeFilterCount,
            onToggle: () => setState(() => _filtersOpen = !_filtersOpen),
            risks: _risks,
            onToggleRisk: (r) => setState(() {
              if (_risks.contains(r)) {
                _risks.remove(r);
              } else {
                _risks.add(r);
              }
            }),
            teams: _teams,
            onToggleTeam: (team) => setState(() {
              if (_teams.contains(team)) {
                _teams.remove(team);
              } else {
                _teams.add(team);
              }
            }),
            onClearTeams: () => setState(_teams.clear),
          ),

          if (_request != null) ...[
            const SizedBox(height: 22),
            Text('RÉSULTATS',
                style: TextStyle(
                    color: AppColors.light,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            const SizedBox(height: 8),
            _SortBar(value: _sort, onChanged: _changeSort),
            _Results(request: _request!),
          ],
          const ResponsibleGamingNote(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: WobbleButton(label: 'Crée ton prono !', onPressed: _submit),
      ),
    );
  }
}

class _StakeTargetBox extends StatelessWidget {
  const _StakeTargetBox(
      {required this.stake, required this.target, required this.onChanged});
  final TextEditingController stake;
  final TextEditingController target;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('TA MISE DE DÉPART',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
            Expanded(
              child: Text('TON OBJECTIF',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: _TrapField(
                    svg: Assets.boxStake,
                    controller: stake,
                    onChanged: onChanged,
                    align: TextAlign.left),
              ),
              Expanded(
                child: _TrapField(
                    svg: Assets.boxTarget,
                    controller: target,
                    onChanged: onChanged,
                    align: TextAlign.right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrapField extends StatelessWidget {
  const _TrapField(
      {required this.svg,
      required this.controller,
      required this.onChanged,
      required this.align});
  final String svg;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Slight card tint behind so the translucent shape reads in light mode.
        Container(color: AppColors.card.withValues(alpha: 0.4)),
        Positioned.fill(child: SvgPicture.asset(svg, fit: BoxFit.fill)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              textAlign: align,
              style: tabularNumberStyle(TextStyle(
                  color: AppColors.light,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Green -> red gradient bar: more multiplier = more segments lit.
class _RiskBar extends StatelessWidget {
  const _RiskBar({required this.multiplier});
  final double multiplier;
  static const _segments = 10;

  @override
  Widget build(BuildContext context) {
    final lit = multiplier <= 1 ? 0 : multiplier.clamp(1, 10).ceil();
    return Row(
      children: [
        for (var i = 0; i < _segments; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 12,
              color: _color(i).withValues(alpha: i < lit ? 1 : 0.22),
            ),
          ),
        ],
      ],
    );
  }

  Color _color(int i) => Color.lerp(
        const Color(0xFF7CE37C),
        const Color(0xFFE35F5F),
        i / (_segments - 1),
      )!;
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.open,
    required this.activeCount,
    required this.onToggle,
    required this.risks,
    required this.onToggleRisk,
    required this.teams,
    required this.onToggleTeam,
    required this.onClearTeams,
  });
  final bool open;
  final int activeCount;
  final VoidCallback onToggle;
  final Set<RiskLevel> risks;
  final ValueChanged<RiskLevel> onToggleRisk;
  final Set<String> teams;
  final ValueChanged<String> onToggleTeam;
  final VoidCallback onClearTeams;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            left: -6,
            child: RotatedBox(
              quarterTurns: 2,
              child: SvgPicture.asset(Assets.triangleTopMatch, width: 42),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onToggle,
                  child: Row(
                    children: [
                      Text('FILTRES',
                          style: TextStyle(
                              color: AppColors.light,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 1)),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 1),
                          color: AppColors.teal,
                          child: Text('$activeCount',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                      const Spacer(),
                      Icon(open ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.muted),
                    ],
                  ),
                ),
                if (open) ...[
                  const Divider(color: Color(0xFF343B3A)),
                  const SizedBox(height: 4),
                  Text('NIVEAU DE CÔTE',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  _RiskSelector(selected: risks, onToggle: onToggleRisk),
                  const SizedBox(height: 16),
                  Text('ÉQUIPES',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  _TeamFilter(
                      selected: teams,
                      onToggle: onToggleTeam,
                      onClear: onClearTeams),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.value, required this.onChanged});
  final ComboSort value;
  final ValueChanged<ComboSort> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(Icons.sort, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Text('Trier :', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<ComboSort>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.card,
              underline: const SizedBox.shrink(),
              style: TextStyle(
                  color: AppColors.light,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              items: [
                for (final s in ComboSort.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (s) => s != null ? onChanged(s) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamFilter extends ConsumerWidget {
  const _TeamFilter(
      {required this.selected, required this.onToggle, required this.onClear});
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(upcomingTeamsProvider);
    return teams.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator())),
      error: (_, __) => Text('Équipes indisponibles.',
          style: TextStyle(color: AppColors.muted, fontSize: 12)),
      data: (list) {
        if (list.isEmpty) {
          return Text('Aucune équipe à venir.',
              style: TextStyle(color: AppColors.muted, fontSize: 12));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selected.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: onClear,
                    child: Text('Tout effacer (${selected.length})',
                        style: const TextStyle(
                            color: AppColors.teal, fontSize: 12))),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final team in list)
                  GestureDetector(
                    onTap: () => onToggle(team),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      color: selected.contains(team)
                          ? AppColors.teal
                          : AppColors.dark,
                      child: Text(team,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected.contains(team)
                                  ? Colors.white
                                  : AppColors.light)),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Results extends ConsumerStatefulWidget {
  const _Results({required this.request});
  final ComboRequest request;
  @override
  ConsumerState<_Results> createState() => _ResultsState();
}

class _ResultsState extends ConsumerState<_Results> {
  int _visible = kComboCount;

  @override
  void didUpdateWidget(_Results old) {
    super.didUpdateWidget(old);
    if (old.request != widget.request) _visible = kComboCount;
  }

  @override
  Widget build(BuildContext context) {
    final combos = ref.watch(comboProvider(widget.request));
    return combos.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorRetry(
          message: 'Erreur lors de la génération.\n$e',
          onRetry: () => ref.invalidate(comboProvider(widget.request))),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
                'Aucun combiné ne correspond à ces paramètres. '
                'Essaie un objectif différent ou élargis tes filtres.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          );
        }
        final shown = list.length < _visible ? list.length : _visible;
        return Column(
          children: [
            for (var i = 0; i < shown; i++)
              _ComboCard(combo: list[i], best: i == 0),
            if (shown < list.length)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _visible += kComboCount),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.expand_more, size: 20),
                  label: const Text('Voir plus',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ComboCard extends StatelessWidget {
  const _ComboCard({required this.combo, required this.best});
  final Combo combo;
  final bool best;

  @override
  Widget build(BuildContext context) {
    // Group legs by match (same-match multis show under one header).
    final byMatch = <String, List<ComboLeg>>{};
    for (final l in combo.legs) {
      byMatch.putIfAbsent(l.matchLabel, () => []).add(l);
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: AppColors.card,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            left: -6,
            child: RotatedBox(
              quarterTurns: 2,
              child: SvgPicture.asset(Assets.triangleTopMatch, width: 42),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('COMBINÉ',
                        style: TextStyle(
                            color: AppColors.light,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 1)),
                    Text('${(combo.probability * 100).round()}% de réussite',
                        style: const TextStyle(
                            color: Color(0xFF5FE3B6),
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ],
                ),
                const Divider(color: Color(0xFF343B3A)),
                for (final entry in byMatch.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(entry.key.toUpperCase(),
                        style: TextStyle(
                            color: AppColors.light,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                  for (final l in entry.value) _LegRow(leg: l),
                ],
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF343B3A)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${combo.potentialWin.toStringAsFixed(2)}€',
                        style: TextStyle(
                            color: AppColors.light,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    Text('×${combo.totalOdds.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                  ],
                ),
                Text('Gain potentiel. Peut varier selon les bookmakers.',
                    style: TextStyle(color: AppColors.muted, fontSize: 10)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _shareText(combo)));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Combiné copié — prêt à partager !')));
                    },
                    icon: const Icon(Icons.share, size: 16, color: AppColors.teal),
                    label: const Text('Partager',
                        style: TextStyle(color: AppColors.teal, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _shareText(Combo combo) {
    final buffer = StringBuffer('🎯 Mon combiné ProScores\n');
    for (final l in combo.legs) {
      buffer.writeln('• ${l.matchLabel} · ${l.selection.label} '
          '(${l.selection.odd.toStringAsFixed(2)})');
    }
    buffer.writeln('Cote totale ×${combo.totalOdds.toStringAsFixed(2)} · '
        '${(combo.probability * 100).round()}% de réussite');
    buffer.write('Gain potentiel : ${combo.potentialWin.toStringAsFixed(2)}€');
    return buffer.toString();
  }
}

// One pick line: ball icon (result markets) or whistle icon (goals) + label.
class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg});
  final ComboLeg leg;

  bool get _isResult => leg.market.family == MarketFamily.result;

  String get _pick {
    final parts = leg.matchLabel.split(' - ');
    final home = parts.isNotEmpty ? parts.first : '1';
    final away = parts.length > 1 ? parts.last : '2';
    if (leg.market == MarketType.resultat1x2) {
      return switch (leg.selection.label) {
        '1' => home,
        'N' => 'Nul',
        '2' => away,
        _ => leg.selection.label,
      };
    }
    return leg.selection.label;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(_isResult ? Assets.iconBall : Assets.iconWhistle,
                  width: 14,
                  height: 14,
                  color: AppColors.teal,
                  colorBlendMode: BlendMode.srcIn),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_pick, style: const TextStyle(fontSize: 13))),
              Text(leg.selection.odd.toStringAsFixed(2),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 2),
            child: Text(BetExplainer.explain(leg),
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

class _RiskSelector extends StatelessWidget {
  const _RiskSelector({required this.selected, required this.onToggle});
  final Set<RiskLevel> selected;
  final ValueChanged<RiskLevel> onToggle;
  @override
  Widget build(BuildContext context) {
    const options = <RiskLevel>[
      RiskLevel.peuRisque,
      RiskLevel.modere,
      RiskLevel.risque,
    ];
    String labelFor(RiskLevel r) => switch (r) {
          RiskLevel.peuRisque => 'FAIBLE',
          RiskLevel.modere => 'MOYENNE',
          _ => 'ÉLEVÉE',
        };
    return Row(
      children: [
        for (final r in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => onToggle(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color:
                      selected.contains(r) ? AppColors.teal : AppColors.dark,
                  child: Text(labelFor(r),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected.contains(r)
                              ? Colors.white
                              : AppColors.light)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
