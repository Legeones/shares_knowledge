import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../logic/form_validators.dart';
import '../../logic/past_trader/trading.dart';
import '../../providers/past_trader/trader_game_controller.dart';

/// Fenêtre d'ordre : montant en dollars, raccourcis 25 / 50 / 100 %.
/// Renvoie true si l'ordre a été exécuté.
Future<bool> showOrderSheet(
  BuildContext context, {
  required TraderGameController controller,
  required String symbol,
  required String name,
  required TradeSide side,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _OrderSheet(
      controller: controller,
      symbol: symbol,
      name: name,
      side: side,
    ),
  );
  return done ?? false;
}

class _OrderSheet extends StatefulWidget {
  final TraderGameController controller;
  final String symbol;
  final String name;
  final TradeSide side;

  const _OrderSheet({
    required this.controller,
    required this.symbol,
    required this.name,
    required this.side,
  });

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  final _amount = TextEditingController();
  String? _error;
  bool _all = false; // « 100 % » d'une vente = tout vendre

  bool get _isBuy => widget.side == TradeSide.buy;
  TraderGame get _game => widget.controller.game;

  /// Montant maximal : le cash pour un achat, la position pour une vente.
  double get _max => _isBuy ? _game.cash : _game.positionValue(widget.symbol);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _setFraction(double fraction) {
    setState(() {
      _all = !_isBuy && fraction == 1;
      _error = null;
      _amount.text = (_max * fraction).toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  void _submit() {
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Indique un montant positif.');
      return;
    }
    final error = _isBuy
        ? widget.controller.buy(widget.symbol, amount)
        : widget.controller.sell(widget.symbol, amount: amount, all: _all);
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = _game.priceOf(widget.symbol)!;
    final amount = parseAmount(_amount.text) ?? 0;

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
            '${_isBuy ? 'Acheter' : 'Vendre'} ${widget.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            'Cours de clôture du ${formatDate(_game.current)} : '
            '${formatMoney(price, 'USD')}',
          ),
          Text(
            _isBuy
                ? 'Cash disponible : ${formatMoney(_game.cash, 'USD')}'
                : 'Tu détiens : ${formatMoney(_max, 'USD')}',
          ),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final f in const [0.25, 0.5, 1.0])
                ActionChip(
                  label: Text(
                    f == 1
                        ? (_isBuy ? 'Tout' : 'Tout vendre')
                        : '${(f * 100).round()} %',
                  ),
                  onPressed: () => _setFraction(f),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '≈ ${formatUnits(amount / price)} part(s). Ordre exécuté au cours '
            'de clôture du jour, sans frais.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(_isBuy ? 'Confirmer l’achat' : 'Confirmer la vente'),
          ),
        ],
      ),
    );
  }
}
