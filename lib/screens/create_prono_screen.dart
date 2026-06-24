import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/combo.dart';
import '../models/risk_level.dart';
import '../providers/combo_provider.dart';
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
  RiskLevel _risk = RiskLevel.modere;
  ComboRequest? _request;

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
      _request =
          ComboRequest(stake: _stakeVal, target: _targetVal, risk: _risk);
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
          if (_multiplier > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  'Multiplicateur visé × ${_multiplier.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 16),
          const Text('Niveau de risque',
              style: TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _RiskSelector(
              value: _risk, onChanged: (r) => setState(() => _risk = r)),
          const SizedBox(height: 16),
          WobbleButton(
            label: 'Générer mes combinés',
            onPressed: _stakeVal > 0 && _targetVal > 0 ? _submit : null,
          ),
          const ResponsibleGamingNote(),
          if (_request != null) _Results(request: _request!),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.request});
  final ComboRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combos = ref.watch(comboProvider(request));
    return combos.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorRetry(
          message: 'Erreur lors de la génération.\n$e',
          onRetry: () => ref.invalidate(comboProvider(request))),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
                'Aucun combiné ne correspond à ces paramètres. '
                'Essaie un objectif différent ou un autre niveau de risque.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < list.length; i++)
              _ComboCard(combo: list[i], best: i == 0),
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
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text('${l.matchLabel} · ${l.selection.label}',
                            style: const TextStyle(fontSize: 12))),
                    Text(l.selection.odd.toStringAsFixed(2),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
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
        ],
      ),
    );
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
              style: const TextStyle(
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
  final RiskLevel value;
  final ValueChanged<RiskLevel> onChanged;
  @override
  Widget build(BuildContext context) {
    const options = [RiskLevel.peuRisque, RiskLevel.modere, RiskLevel.risque];
    return Row(
      children: [
        for (final r in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: value == r ? AppColors.teal : AppColors.card,
                  child: Text(r.label,
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
