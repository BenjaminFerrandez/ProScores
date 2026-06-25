import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/combo.dart';
import '../models/combo_sort.dart';
import '../models/risk_level.dart';
import '../providers/combo_provider.dart';
import '../services/bet_explainer.dart';
import '../widgets/error_retry.dart';
import '../widgets/responsible_gaming_note.dart';
import '../widgets/wobble_button.dart';

class CreatePronoScreen extends ConsumerStatefulWidget {
  const CreatePronoScreen({super.key});
  @override
  ConsumerState<CreatePronoScreen> createState() => _CreatePronoScreenState();
}

class _CreatePronoScreenState extends ConsumerState<CreatePronoScreen> {
  final _stake = TextEditingController(text: '10');
  final _target = TextEditingController(text: '25');
  RiskLevel? _risk; // null = Tous (optional)
  final Set<String> _teams = {};
  ComboSort _sort = ComboSort.probabilityDesc;
  ComboRequest? _request;
  bool _filtersOpen = false;

  int get _activeFilterCount =>
      (_risk != null ? 1 : 0) + (_teams.isNotEmpty ? 1 : 0);

  @override
  void dispose() {
    _stake.dispose();
    _target.dispose();
    super.dispose();
  }

  double get _stakeVal => double.tryParse(_stake.text) ?? 0;
  double get _targetVal => double.tryParse(_target.text) ?? 0;
  double get _multiplier => _stakeVal > 0 ? _targetVal / _stakeVal : 0;

  void _submit() {
    setState(() {
      _request = ComboRequest(
        stake: _stakeVal,
        target: _targetVal,
        risk: _risk,
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
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: SquareIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop()),
            ),
          ),
          title: const Text('Crée ton prono')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberField(
              label: 'Ta mise de départ (€)',
              controller: _stake,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          _NumberField(
              label: 'Ton objectif de gain (€)',
              controller: _target,
              onChanged: (_) => setState(() {})),
          if (_targetVal > 0 && _stakeVal > 0 && _targetVal <= _stakeVal)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                  'L\'objectif de gain doit être supérieur à la mise.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Color(0xFFE35F5F), fontWeight: FontWeight.w600)),
            )
          else if (_multiplier > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  'Multiplicateur visé × ${_multiplier.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 20),

          // ---- Optional, collapsible filters ----
          InkWell(
            onTap: () => setState(() => _filtersOpen = !_filtersOpen),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text('Filtres (optionnels)',
                      style: TextStyle(
                          color: AppColors.light,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('$_activeFilterCount',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                  const Spacer(),
                  Icon(_filtersOpen ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.muted),
                ],
              ),
            ),
          ),
          if (_filtersOpen) ...[
            const SizedBox(height: 8),
            Text('Laisse vide pour voir tous les combinés possibles.',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 14),
            Text('Niveau de risque',
                style: TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _RiskSelector(
                value: _risk, onChanged: (r) => setState(() => _risk = r)),
            const SizedBox(height: 16),
            Text('Équipes',
                style: TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _TeamFilter(
              selected: _teams,
              onToggle: (team) => setState(() {
                if (_teams.contains(team)) {
                  _teams.remove(team);
                } else {
                  _teams.add(team);
                }
              }),
              onClear: () => setState(_teams.clear),
            ),
          ],
          const SizedBox(height: 18),

          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size.fromHeight(52)),
            onPressed: _stakeVal > 0 && _targetVal > _stakeVal ? _submit : null,
            child: const Text('Générer mes combinés',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const ResponsibleGamingNote(),
          if (_request != null) ...[
            _SortBar(value: _sort, onChanged: _changeSort),
            _Results(request: _request!),
          ],
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
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Icon(Icons.sort, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Text('Trier :',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
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
      {required this.selected,
      required this.onToggle,
      required this.onClear});
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
                  FilterChip(
                    label: Text(team),
                    selected: selected.contains(team),
                    showCheckmark: false,
                    backgroundColor: AppColors.card,
                    selectedColor: AppColors.teal,
                    labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected.contains(team)
                            ? Colors.white
                            : AppColors.light),
                    side: BorderSide(
                        color: selected.contains(team)
                            ? AppColors.teal
                            : const Color(0xFF343B3A)),
                    onSelected: (_) => onToggle(team),
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
    // New generation or new sort -> show the first page again.
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
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(
            color: best ? AppColors.teal : const Color(0xFF313837)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Combiné · ${combo.legs.length} jambes',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${(combo.probability * 100).round()}% de réussite',
                  style: const TextStyle(
                      color: Color(0xFF5FE3B6),
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ...combo.legs.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(
                                '${l.matchLabel} · ${l.selection.label}',
                                style: const TextStyle(fontSize: 12))),
                        Text(l.selection.odd.toStringAsFixed(2),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.subdirectory_arrow_right,
                              size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(BetExplainer.explain(l),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(color: Color(0xFF343B3A)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cote totale ×${combo.totalOdds.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w800)),
              Text('Gain potentiel ${combo.potentialWin.toStringAsFixed(2)}€',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
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

class _NumberField extends StatelessWidget {
  const _NumberField(
      {required this.label,
      required this.controller,
      required this.onChanged});
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      );
}

class _RiskSelector extends StatelessWidget {
  const _RiskSelector({required this.value, required this.onChanged});
  final RiskLevel? value;
  final ValueChanged<RiskLevel?> onChanged;
  @override
  Widget build(BuildContext context) {
    // null = Tous, then the three bands.
    const options = <RiskLevel?>[
      null,
      RiskLevel.peuRisque,
      RiskLevel.modere,
      RiskLevel.risque
    ];
    String labelFor(RiskLevel? r) => r?.label ?? 'Tous';
    return Row(
      children: [
        for (final r in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == r ? AppColors.teal : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(labelFor(r),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
