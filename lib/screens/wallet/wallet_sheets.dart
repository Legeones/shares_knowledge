import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../logic/form_validators.dart';
import '../../models/wallet/wallet.dart';

/// Fenêtre de saisie d'un montant (dépôt, achat, vente).
///
/// [onSubmit] passe l'ordre et renvoie le message d'erreur, ou null : la
/// fenêtre se ferme alors et renvoie true. [max] active les raccourcis
/// 25 / 50 / 100 % ; [all] vaut vrai si « 100 % » a été choisi.
Future<bool> showAmountSheet(
  BuildContext context, {
  required String title,
  required List<String> lines,
  required String confirmLabel,
  required Future<String?> Function(double amount, bool all) onSubmit,
  double? max,
  String allLabel = 'Tout',
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AmountSheet(
      title: title,
      lines: lines,
      confirmLabel: confirmLabel,
      onSubmit: onSubmit,
      max: max,
      allLabel: allLabel,
    ),
  );
  return done ?? false;
}

class _AmountSheet extends StatefulWidget {
  final String title;
  final List<String> lines;
  final String confirmLabel;
  final Future<String?> Function(double amount, bool all) onSubmit;
  final double? max;
  final String allLabel;

  const _AmountSheet({
    required this.title,
    required this.lines,
    required this.confirmLabel,
    required this.onSubmit,
    required this.max,
    required this.allLabel,
  });

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _amount = TextEditingController();
  String? _error;
  bool _all = false;
  bool _sending = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _setFraction(double fraction) => setState(() {
    _all = fraction == 1;
    _error = null;
    _amount.text = (widget.max! * fraction)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  });

  Future<void> _submit() async {
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Indique un montant positif.');
      return;
    }
    setState(() => _sending = true);
    final error = await widget.onSubmit(amount, _all);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = error;
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.max;
    return _SheetBody(
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        for (final line in widget.lines) Text(line),
        const SizedBox(height: 16),
        TextField(
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Montant',
            suffixText: '\$',
            errorText: _error,
          ),
          onChanged: (_) => setState(() {
            _all = false;
            _error = null;
          }),
        ),
        if (max != null && max > 0) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final f in const [0.25, 0.5, 1.0])
                ActionChip(
                  label: Text(
                    f == 1 ? widget.allLabel : '${(f * 100).round()} %',
                  ),
                  onPressed: () => _setFraction(f),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _sending ? null : _submit,
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Nouveau versement mensuel : montant et jour du mois.
Future<({double amount, int day})?> showPlanSheet(
  BuildContext context, {
  required String assetName,
}) => showModalBottomSheet<({double amount, int day})>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _PlanSheet(assetName: assetName),
);

class _PlanSheet extends StatefulWidget {
  final String assetName;
  const _PlanSheet({required this.assetName});

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  final _amount = TextEditingController(text: '100');
  int _day = 5;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Indique un montant positif.');
      return;
    }
    Navigator.pop(context, (amount: amount, day: _day));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      children: [
        Text(
          'Versement mensuel',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Chaque mois, cette somme est déposée puis investie dans '
          '${widget.assetName}, au cours de clôture du jour prévu (ou du '
          'jour de bourse suivant).',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Montant par mois',
            suffixText: '\$',
            errorText: _error,
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 16),
        Text('Le $_day de chaque mois'),
        // Jusqu'au 28 : ce jour existe dans tous les mois.
        Slider(
          value: _day.toDouble(),
          min: 1,
          max: 28,
          divisions: 27,
          label: '$_day',
          onChanged: (v) => setState(() => _day = v.round()),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: const Text('Programmer le versement'),
        ),
      ],
    );
  }
}

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
    return _SheetBody(
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
    );
  }
}

/// Mise en page commune des fenêtres : marges et place pour le clavier.
class _SheetBody extends StatelessWidget {
  final List<Widget> children;
  const _SheetBody({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
