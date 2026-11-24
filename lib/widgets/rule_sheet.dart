import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../logic/form_validators.dart';
import '../models/position_rule.dart';

/// Règles de vente automatique d'une position. Renvoie la règle choisie
/// (vide = aucune), ou null si la fenêtre est fermée sans enregistrer.
Future<PositionRule?> showRuleSheet(
  BuildContext context, {
  required PositionRule rule,
  required String assetName,
  required double averagePrice,
}) => showModalBottomSheet<PositionRule>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) =>
      _RuleSheet(rule: rule, assetName: assetName, averagePrice: averagePrice),
);

class _RuleSheet extends StatefulWidget {
  final PositionRule rule;
  final String assetName;
  final double averagePrice;

  const _RuleSheet({
    required this.rule,
    required this.assetName,
    required this.averagePrice,
  });

  @override
  State<_RuleSheet> createState() => _RuleSheetState();
}

class _RuleSheetState extends State<_RuleSheet> {
  late final _stop = TextEditingController(
    text: _percent(widget.rule.stopLoss),
  );
  late final _take = TextEditingController(
    text: _percent(widget.rule.takeProfit),
  );
  String? _error;

  static String _percent(double? v) =>
      v == null ? '' : (v * 100).round().toString();

  @override
  void dispose() {
    _stop.dispose();
    _take.dispose();
    super.dispose();
  }

  /// Champ vide = pas de règle ; sinon un pourcentage entre 1 et 1000.
  double? _read(TextEditingController c, {required double max}) {
    final text = c.text.trim();
    if (text.isEmpty) return null;
    final v = parseAmount(text);
    if (v == null || v < 1 || v > max) throw FormatException('$v');
    return v / 100;
  }

  void _submit() {
    try {
      Navigator.pop(
        context,
        PositionRule(
          symbol: widget.rule.symbol,
          stopLoss: _read(_stop, max: 99),
          takeProfit: _read(_take, max: 1000),
        ),
      );
    } on FormatException {
      setState(
        () =>
            _error = 'Stop-loss entre 1 et 99 %, objectif entre 1 et 1 000 %.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avg = formatMoney(widget.averagePrice, 'USD');
    return Padding(
      // Laisse la place au clavier.
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ventes automatiques',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${widget.assetName} est vendu en entier dès qu’un seuil est '
            'atteint au cours de clôture. Prix moyen d’achat : $avg.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stop,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stop-loss : vendre si le cours perd',
              suffixText: '%',
              helperText: 'Limite la perte. Vide = pas de stop-loss.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _take,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Objectif : vendre si le cours gagne',
              suffixText: '%',
              helperText: 'Encaisse le gain. Vide = pas d’objectif.',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

/// « Stop-loss −20 % · objectif +50 % », ou null sans règle.
String? ruleText(PositionRule? rule) {
  if (rule == null || rule.isEmpty) return null;
  return [
    if (rule.stopLoss case final s?) 'Stop-loss −${(s * 100).round()} %',
    if (rule.takeProfit case final t?) 'objectif +${(t * 100).round()} %',
  ].join(' · ');
}
