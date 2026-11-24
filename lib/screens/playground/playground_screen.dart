import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sections.dart';
import '../../logic/form_validators.dart';
import '../../models/asset.dart';
import '../../models/simulation.dart';
import '../../providers/playground/playground_provider.dart';
import '../../widgets/playground/date_form_field.dart';
import '../../widgets/glass.dart';
import '../../widgets/section_card.dart';
import '../wallet/wallet_view.dart';
import 'asset_picker_screen.dart';
import 'simulation_result_screen.dart';

/// Formulaire de configuration du Playground.
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  /// Clé qui donne accès au Form pour appeler validate().
  final _formKey = GlobalKey<FormState>();

  /// Contrôleur du champ montant : permet de lire le texte saisi.
  final _amountController = TextEditingController(text: '1000');

  late final DateTime _today;
  late final DateTime _yesterday;
  Asset? _asset;
  late DateTime _start;
  late DateTime _end;
  InvestMode _mode = InvestMode.lumpSum;

  /// Faux : le simulateur (le passé). Vrai : le portefeuille en temps réel.
  bool _live = false;

  /// Après un premier envoi raté, les erreurs se mettent à jour en direct.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime.utc(now.year, now.month, now.day);
    _yesterday = _today.subtract(const Duration(days: 1));
    // Valeurs proposées par défaut : les 5 dernières années.
    _end = _yesterday;
    _start = DateTime.utc(_today.year - 5, _today.month, _today.day);
  }

  @override
  void dispose() {
    _amountController.dispose(); // libère le contrôleur avec l'écran
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    final params = SimulationParams(
      asset: _asset!,
      amount: parseAmount(_amountController.text)!,
      start: _start,
      end: _end,
      mode: _mode,
    );
    context.read<PlaygroundProvider>().simulate(params);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SimulationResultScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      child: ListView(
        padding: tabListPadding(context),
        children: [
          SectionHero(
            section: playgroundSection,
            children: [
              Text(
                _live
                    ? 'Ton portefeuille avance avec les vrais cours, jour '
                          'après jour, à partir d’aujourd’hui.'
                    : 'Choisis un actif, une somme et une période : on rejoue '
                          'l’histoire avec les vrais cours.',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Simulateur'),
                icon: Icon(Icons.history_rounded),
              ),
              ButtonSegment(
                value: true,
                label: Text('Mon portefeuille'),
                icon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ],
            selected: {_live},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _live = s.first),
          ),
          const SizedBox(height: 20),
          if (_live) const WalletView(),
          if (!_live) ...[
            const GroupTitle('Ta simulation'),
            _AssetFormField(
              onChanged: (asset) => setState(() => _asset = asset),
            ),
            const SizedBox(height: 16),
            // Les deux façons d'investir de la leçon DCA.
            SegmentedButton<InvestMode>(
              segments: const [
                ButtonSegment(
                  value: InvestMode.lumpSum,
                  label: Text('En une fois'),
                  icon: Icon(Icons.savings_outlined),
                ),
                ButtonSegment(
                  value: InvestMode.monthly,
                  label: Text('Chaque mois'),
                  icon: Icon(Icons.calendar_month_outlined),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: _mode == InvestMode.monthly
                    ? 'Montant versé chaque mois'
                    : 'Montant investi',
                suffixText: _asset?.currency ?? '',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: validateAmount,
            ),
            const SizedBox(height: 16),
            DateFormField(
              label: _mode == InvestMode.monthly
                  ? 'Premier versement'
                  : 'Date d’achat',
              initialDate: _start,
              firstDate: earliestDate,
              lastDate: _yesterday,
              onChanged: (d) => setState(() => _start = d),
              validator: (d) => validateStartDate(d, end: _end),
            ),
            const SizedBox(height: 16),
            DateFormField(
              label: 'Date de fin',
              initialDate: _end,
              firstDate: earliestDate,
              lastDate: _yesterday,
              onChanged: (d) => setState(() => _end = d),
              validator: (d) => validateEndDate(d, today: _today),
            ),
            const SizedBox(height: 8),
            Text(
              _mode == InvestMode.monthly
                  ? 'Un achat par mois au cours de clôture, le même jour du mois '
                        '(ou le jour de bourse suivant), sans frais ni dividendes. '
                        'Montants dans la devise de l’actif.'
                  : 'Achat unique au cours de clôture du premier jour de bourse, '
                        'sans frais ni dividendes. Montants dans la devise de '
                        'l’actif.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lancer la simulation'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Champ « actif » : affiche l'actif choisi, ouvre la liste au toucher.
class _AssetFormField extends FormField<Asset> {
  _AssetFormField({required ValueChanged<Asset> onChanged})
    : super(
        validator: (asset) => asset == null ? 'Choisis un actif.' : null,
        builder: (field) {
          Future<void> pick() async {
            final asset = await Navigator.of(field.context).push<Asset>(
              MaterialPageRoute(builder: (_) => const AssetPickerScreen()),
            );
            if (asset == null) return;
            field.didChange(asset);
            onChanged(asset);
          }

          final asset = field.value;
          return InkWell(
            onTap: pick,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Actif',
                errorText: field.errorText,
                suffixIcon: const Icon(Icons.chevron_right),
              ),
              child: Text(
                asset == null
                    ? 'Toucher pour choisir'
                    : '${asset.name} (${asset.symbol})',
              ),
            ),
          );
        },
      );
}
