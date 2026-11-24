import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../logic/form_validators.dart';
import '../../models/asset.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/glass.dart';
import '../../widgets/rule_sheet.dart';
import '../../widgets/simple_line_chart.dart';
import '../../widgets/wallet/allocation_chart.dart';
import '../playground/asset_picker_screen.dart';
import '../../logic/wallet/wallet_engine.dart';
import '../../models/position_rule.dart';
import '../../models/wallet/wallet.dart';
import '../../providers/wallet/wallet_provider.dart';
import 'wallet_sheets.dart';

/// « Mon portefeuille » : le portefeuille en temps réel du Playground.
class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  @override
  void initState() {
    super.initState();
    // Chargé à la première ouverture seulement : les cours sont
    // téléchargés quand on en a besoin, pas au lancement de l'application.
    final wallet = context.read<WalletProvider>();
    if (!wallet.loaded && !wallet.loading) wallet.load();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    if (!wallet.loaded) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!wallet.exists) return const _CreateWallet();
    return _Wallet(wallet: wallet);
  }
}

/// Avant la création : explications et capital de départ.
class _CreateWallet extends StatefulWidget {
  const _CreateWallet();

  @override
  State<_CreateWallet> createState() => _CreateWalletState();
}

class _CreateWalletState extends State<_CreateWallet> {
  final _capital = TextEditingController(text: '10000');
  String? _error;

  @override
  void dispose() {
    _capital.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final text = _capital.text.trim();
    final capital = text.isEmpty ? 0.0 : parseAmount(text);
    if (capital == null || capital < 0) {
      setState(() => _error = 'Indique un montant (0 pour commencer vide).');
      return;
    }
    await context.read<WalletProvider>().create(capital);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupTitle('Mon portefeuille'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in const [
                  'Un vrai portefeuille, en temps réel : il démarre '
                      'aujourd’hui et grandit avec les vrais cours, jour '
                      'après jour.',
                  'Achète et vends quand tu veux, au dernier cours de '
                      'clôture connu.',
                  'Programme des versements mensuels (DCA) : ils sont '
                      'exécutés automatiquement, même application fermée.',
                  'Protège une position avec un stop-loss, ou encaisse un '
                      'gain avec un objectif de vente.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 10),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.blue,
                          ),
                        ),
                        Expanded(child: Text(line)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _capital,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Capital de départ',
                    suffixText: '\$',
                    helperText: 'Tu pourras déposer plus d’argent ensuite.',
                    errorText: _error,
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _create,
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Créer mon portefeuille'),
        ),
      ],
    );
  }
}

class _Wallet extends StatelessWidget {
  final WalletProvider wallet;
  const _Wallet({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final state = wallet.state;
    final value = wallet.totalValue;
    final gain = value - state.deposited;
    final history = wallet.history;
    final pricesDate = wallet.pricesDate;
    final hero = heroText(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mon portefeuille', style: hero.titleMedium),
              Text(
                'Depuis le ${formatDate(wallet.createdAt)}'
                '${pricesDate == null ? '' : ' · cours du ${formatDate(pricesDate)}'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(value, 'USD'),
                  style: hero.displaySmall,
                ),
              ),
              const SizedBox(height: 8),
              HeroPill(
                child: Text(
                  state.deposited == 0
                      ? 'Rien de déposé pour l’instant'
                      : '${formatSignedMoney(gain, 'USD')} · '
                            '${formatPercent(gain / state.deposited)} · '
                            '${formatMoney(state.deposited, 'USD')} déposés',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (wallet.warning != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GlassMessage(
              'Cours pas à jour : ${wallet.warning}',
              icon: Icons.cloud_off_rounded,
              color: AppColors.loss,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _buy(context),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Acheter'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _deposit(context),
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Déposer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const GroupTitle('Évolution'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: history.length < 2
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'La courbe apparaîtra après les prochains jours de '
                      'bourse : le portefeuille avance en temps réel.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : SimpleLineChart(
                    points: [
                      for (final p in history) (date: p.date, value: p.value),
                    ],
                    reference: state.deposited,
                  ),
          ),
        ),
        if (state.holdings.isNotEmpty) ...[
          const SizedBox(height: 20),
          const GroupTitle('Répartition'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AllocationChart(
                positions: [
                  for (final MapEntry(key: symbol, value: h)
                      in state.holdings.entries)
                    (
                      label: wallet.nameOf(symbol),
                      value:
                          h.units * (wallet.priceOf(symbol) ?? h.averagePrice),
                    ),
                ],
                cash: state.cash,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const GroupTitle('Positions'),
        Card(
          child: Column(
            children: [
              for (final MapEntry(key: symbol, value: h)
                  in state.holdings.entries)
                _PositionTile(wallet: wallet, symbol: symbol, holding: h),
              ListTile(
                leading: const IconTile(Icons.payments_outlined, size: 38),
                title: const Text('Cash disponible'),
                trailing: Text(formatMoney(state.cash, 'USD')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const GroupTitle('Versements mensuels'),
        Card(
          child: Column(
            children: [
              for (final plan in wallet.plans)
                ListTile(
                  leading: const IconTile(Icons.event_repeat_rounded, size: 38),
                  title: Text(
                    '${formatMoney(plan.amount, 'USD')} · ${plan.name}',
                  ),
                  subtitle: Text(
                    'Le ${plan.dayOfMonth} de chaque mois · prochain : '
                    '${formatDate(nextTarget(plan))}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Arrêter ce versement',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _removePlan(context, plan),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add_rounded, color: AppColors.blue),
                title: const Text('Programmer un versement mensuel'),
                onTap: () => _addPlan(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const GroupTitle('Historique'),
        Card(
          child: wallet.transactions.isEmpty
              ? const ListTile(title: Text('Aucune opération pour l’instant.'))
              : Column(
                  children: [
                    for (final t in wallet.transactions.reversed.take(20))
                      _TransactionTile(wallet: wallet, transaction: t),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _reset(context),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Réinitialiser le portefeuille'),
        ),
        Text(
          'Cours de clôture réels (Twelve Data), mis à jour à chaque '
          'ouverture. Sans frais, dividendes ni fiscalité.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<Asset?> _pickAsset(BuildContext context) => Navigator.of(
    context,
  ).push<Asset>(MaterialPageRoute(builder: (_) => const AssetPickerScreen()));

  Future<void> _buy(BuildContext context) async {
    final asset = await _pickAsset(context);
    if (asset == null || !context.mounted) return;
    final price = wallet.priceOf(asset.symbol);
    await showAmountSheet(
      context,
      title: 'Acheter ${asset.name}',
      lines: [
        'Cash disponible : ${formatMoney(wallet.state.cash, 'USD')}',
        price == null
            ? 'Au dernier cours de clôture connu.'
            : 'Dernier cours : ${formatMoney(price, 'USD')}',
      ],
      max: wallet.state.cash,
      confirmLabel: 'Confirmer l’achat',
      onSubmit: (amount, _) =>
          wallet.buy(asset.symbol, amount, name: asset.name),
    );
  }

  Future<void> _deposit(BuildContext context) => showAmountSheet(
    context,
    title: 'Déposer de l’argent',
    lines: const [
      'Ajouté au cash : il ne rapporte rien tant qu’il n’est pas '
          'investi.',
    ],
    confirmLabel: 'Déposer',
    onSubmit: (amount, _) => wallet.deposit(amount),
  );

  Future<void> _addPlan(BuildContext context) async {
    final asset = await _pickAsset(context);
    if (asset == null || !context.mounted) return;
    final plan = await showPlanSheet(context, assetName: asset.name);
    if (plan == null) return;
    await wallet.addPlan(asset, plan.amount, plan.day);
  }

  Future<void> _removePlan(BuildContext context, DcaPlan plan) async {
    final ok = await confirmAction(
      context,
      title: 'Arrêter ce versement ?',
      message:
          'Les achats déjà faits restent dans le portefeuille ; les '
          'prochains n’auront pas lieu.',
      confirmLabel: 'Arrêter',
    );
    if (ok) await wallet.removePlan(plan);
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Réinitialiser le portefeuille ?',
      message:
          'Toutes les positions, opérations et versements programmés '
          'seront effacés.',
      confirmLabel: 'Tout effacer',
    );
    if (ok) await wallet.reset();
  }
}

/// Une position : valeur, gain, règles ; la toucher ouvre ses actions.
class _PositionTile extends StatelessWidget {
  final WalletProvider wallet;
  final String symbol;
  final Holding holding;

  const _PositionTile({
    required this.wallet,
    required this.symbol,
    required this.holding,
  });

  @override
  Widget build(BuildContext context) {
    final price = wallet.priceOf(symbol) ?? holding.averagePrice;
    final value = holding.units * price;
    final change = price / holding.averagePrice - 1;
    final rules = ruleText(wallet.rules[symbol]) ?? '';

    return ListTile(
      leading: const IconTile(Icons.show_chart_rounded, size: 38),
      title: Text(wallet.nameOf(symbol)),
      subtitle: Text(
        '${formatUnits(holding.units)} part(s) · prix moyen '
        '${formatMoney(holding.averagePrice, 'USD')}'
        '${rules.isEmpty ? '' : '\n$rules'}',
      ),
      isThreeLine: rules.isNotEmpty,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatMoney(value, 'USD')),
          Text(
            formatPercent(change),
            style: TextStyle(
              color: change >= 0 ? AppColors.gain : AppColors.loss,
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () => _actions(context),
    );
  }

  Future<void> _actions(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          _PositionSheet(wallet: wallet, symbol: symbol, holding: holding),
    );
    if (!context.mounted || choice == null) return;
    final name = wallet.nameOf(symbol);
    final price = wallet.priceOf(symbol) ?? holding.averagePrice;
    switch (choice) {
      case 'buy':
        await showAmountSheet(
          context,
          title: 'Acheter $name',
          lines: [
            'Cash disponible : ${formatMoney(wallet.state.cash, 'USD')}',
            'Dernier cours : ${formatMoney(price, 'USD')}',
          ],
          max: wallet.state.cash,
          confirmLabel: 'Confirmer l’achat',
          onSubmit: (amount, _) => wallet.buy(symbol, amount),
        );
      case 'sell':
        await showAmountSheet(
          context,
          title: 'Vendre $name',
          lines: [
            'Tu détiens : ${formatMoney(holding.units * price, 'USD')}',
            'Dernier cours : ${formatMoney(price, 'USD')}',
          ],
          max: holding.units * price,
          allLabel: 'Tout vendre',
          confirmLabel: 'Confirmer la vente',
          onSubmit: (amount, all) =>
              wallet.sell(symbol, amount: amount, all: all),
        );
      case 'rule':
        final rule = await showRuleSheet(
          context,
          rule: wallet.rules[symbol] ?? PositionRule(symbol: symbol),
          assetName: name,
          averagePrice: holding.averagePrice,
        );
        if (rule != null) await wallet.setRule(rule);
    }
  }
}

/// Détail d'une position : cours depuis l'achat, gain, règles, actions.
class _PositionSheet extends StatelessWidget {
  final WalletProvider wallet;
  final String symbol;
  final Holding holding;

  const _PositionSheet({
    required this.wallet,
    required this.symbol,
    required this.holding,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final price = wallet.priceOf(symbol) ?? holding.averagePrice;
    final value = holding.units * price;
    final gain = value - holding.cost;
    final prices = wallet.pricesOf(symbol);

    Widget action(IconData icon, String label, String choice) => Expanded(
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context, choice),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(wallet.nameOf(symbol), style: textTheme.titleLarge),
          Text(
            '${formatMoney(value, 'USD')} · '
            '${formatSignedMoney(gain, 'USD')} '
            '(${formatPercent(gain / holding.cost)})',
            style: textTheme.titleSmall?.copyWith(
              color: gain >= 0 ? AppColors.gain : AppColors.loss,
            ),
          ),
          Text(
            '${formatUnits(holding.units)} part(s) · prix moyen d’achat '
            '${formatMoney(holding.averagePrice, 'USD')}',
          ),
          const SizedBox(height: 12),
          // Cours depuis la création ; en pointillés, le prix moyen d'achat.
          SimpleLineChart(
            points: [for (final p in prices) (date: p.date, value: p.close)],
            color: AppColors.turquoise,
            reference: holding.averagePrice,
          ),
          const SizedBox(height: 8),
          Text(
            ruleText(wallet.rules[symbol]) ?? 'Aucune vente automatique.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              action(Icons.add_shopping_cart_rounded, 'Acheter', 'buy'),
              const SizedBox(width: 8),
              action(Icons.sell_outlined, 'Vendre', 'sell'),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'rule'),
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: const Text('Stop-loss et objectif'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletProvider wallet;
  final WalletTransaction transaction;
  const _TransactionTile({required this.wallet, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final (icon, label, sign) = switch (t.type) {
      WalletTxType.deposit => (Icons.savings_outlined, 'Dépôt', '+'),
      WalletTxType.buy => (
        Icons.add_shopping_cart_rounded,
        'Achat ${wallet.nameOf(t.symbol!)}',
        '−',
      ),
      WalletTxType.sell => (
        Icons.sell_outlined,
        'Vente ${wallet.nameOf(t.symbol!)}',
        '+',
      ),
    };
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.blue),
      title: Text(label),
      subtitle: Text('${formatDate(t.date)} · ${t.source.label}'),
      trailing: Text('$sign${formatMoney(t.amount, 'USD')}'),
    );
  }
}
