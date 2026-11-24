import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../logic/foresight/foresight.dart';
import '../../logic/taxes.dart';
import '../../models/foresight/foresight.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/tax_profile_picker.dart';
import '../home/intro_screen.dart';

/// Bilan pédagogique : pourquoi ce résultat est impossible à reproduire.
class ForesightDebriefScreen extends StatefulWidget {
  final ForesightScenario scenario;
  final bool firstLaunch;

  const ForesightDebriefScreen({
    super.key,
    required this.scenario,
    this.firstLaunch = false,
  });

  @override
  State<ForesightDebriefScreen> createState() => _ForesightDebriefScreenState();
}

class _ForesightDebriefScreenState extends State<ForesightDebriefScreen> {
  /// Même réserve plafonnée que le parcours vécu, sans impôts ni retraits :
  /// la seule comparaison qui isole l'effet des impôts et des retraits.
  late final _capped = ForesightRun(widget.scenario, useReserveCaps: true);

  /// Situation du profil ; on peut en essayer une autre ici sans la
  /// modifier dans le profil.
  late TaxProfile _profile =
      context.read<SettingsProvider?>()?.taxProfile() ??
      TaxProfile(taxCountryFor(null));

  @override
  void initState() {
    super.initState();
    // Le bilan compte comme une découverte dans le profil.
    context.read<SettingsProvider?>()?.markForesightSeen(
      widget.scenario.decade,
    );
  }

  String _money(double v) => formatMoney(v, widget.scenario.currency);

  void _continue() {
    if (widget.firstLaunch) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const IntroScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hero = heroText(context);
    // Le parcours vécu : impôts de la situation choisie, retraits et
    // réserve plafonnée.
    final taxed = livedRun(widget.scenario, taxRate: _profile.rateFor);
    // Vendu chaque fois un jour trop tard, avec les mêmes impôts et retraits.
    final soldLate = livedRun(
      widget.scenario,
      taxRate: _profile.rateFor,
      sellOneDayLater: true,
    ).totalWealth;
    final dd = taxed.drawdown;
    final picks = widget.scenario.assetSteps.length;

    return LargeTitleScaffold(
      title: 'Pourquoi c’est impossible',
      automaticallyImplyLeading: !widget.firstLaunch,
      body: ListView(
        padding: pagePadding(context, top: 4),
        children: [
          const PageTitle('Pourquoi c’est impossible'),
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résultat de la démonstration', style: hero.labelLarge),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _money(taxed.totalWealth),
                    style: hero.displaySmall,
                  ),
                ),
                Text(
                  'à partir de ${_money(widget.scenario.initialCapital)}, '
                  'impôts et retraits pour vivre compris. Ce chiffre est '
                  'réel… mais personne ne pouvait l’obtenir.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Reason(
            icon: Icons.visibility_off_outlined,
            title: '1. Il fallait connaître le futur',
            text:
                'Il fallait choisir ces $picks actifs parmi des dizaines de '
                'milliers, et savoir quand attendre en cash. Après coup, les '
                'gagnants paraissent évidents : c’est le biais rétrospectif. '
                'Avant leur hausse, rien ne les distinguait de milliers '
                'd’autres qui ont baissé.',
          ),
          _Reason(
            icon: Icons.timer_outlined,
            title: '2. Un timing parfait, au jour près',
            text:
                'En vendant chaque fois un seul jour de bourse trop tard, '
                'le résultat tombe à ${_money(soldLate)} '
                '(${formatPercent(soldLate / taxed.totalWealth - 1)}). '
                'Acheter au plus bas et vendre au plus haut, $picks fois de '
                'suite, relève de la chance.',
          ),
          _Reason(
            icon: Icons.trending_down,
            title: '3. Des chutes vertigineuses en chemin',
            text:
                'Même ce parcours idéal a vu le patrimoine chuter de '
                '${formatPercent(dd.depth, signed: false)} entre le '
                '${formatDate(taxed.days[dd.peakIndex].date)} et le '
                '${formatDate(taxed.days[dd.troughIndex].date)}. '
                'Sans connaître la suite, qui aurait gardé son calme ?',
          ),
          _TaxSection(
            profile: _profile,
            taxed: taxed,
            money: _money,
            withoutTax: _capped.totalWealth,
            onChanged: (p) => setState(() => _profile = p),
          ),
          const _Reason(
            icon: Icons.receipt_long_outlined,
            title: '5. Frais, liquidité, plateformes',
            text:
                'Chaque achat et chaque vente coûte des frais. Acheter pour '
                'des millions de dollars d’un coup fait monter le prix contre '
                'soi, et une plateforme peut suspendre les échanges au pire '
                'moment.',
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'À retenir : identifier un gagnant après coup est facile ; le '
                'choisir avant sa hausse est presque impossible. Un résultat '
                'passé ne dit rien de l’avenir.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _continue,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(
              widget.firstLaunch ? 'Découvrir SharesKnowledge' : 'Fermer',
            ),
          ),
        ],
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Reason({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      // Espace sous chaque carte : elles se suivent dans la liste.
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « 4. Les impôts et la vie » : impôts de la situation choisie et retraits
/// mensuels pour vivre.
class _TaxSection extends StatelessWidget {
  final TaxProfile profile;
  final ForesightRun taxed;
  final String Function(double) money;
  final ValueChanged<TaxProfile> onChanged;

  /// Capital final sans impôts ni retraits, pour comparer.
  final double withoutTax;

  const _TaxSection({
    required this.profile,
    required this.taxed,
    required this.money,
    required this.onChanged,
    required this.withoutTax,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      // Espace sous chaque carte : elles se suivent dans la liste.
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '4. Les impôts et la vie',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Personne ne laisse dormir son argent sans jamais y toucher ni '
              'payer d’impôts. Ici, chaque mois, 4 % par an du capital sont '
              'retirés pour vivre mieux (au plus l’équivalent de 3 000 \$ '
              'd’aujourd’hui), chaque gain est imposé, et à chaque achat le '
              'surplus au-delà d’une réserve plafonnée est mis à l’abri.',
            ),
            const SizedBox(height: 12),
            TaxProfilePicker(profile: profile, onChanged: onChanged),
            const SizedBox(height: 12),
            Text(
              'Sans impôts ni retraits : ${money(withoutTax)}',
              style: textTheme.bodyMedium,
            ),
            Text(
              'Patrimoine final : ${money(taxed.totalWealth)}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Mis à l’abri en chemin : ${money(taxed.totalSheltered)}'),
            Text('Capital encore investi : ${money(taxed.finalCapital)}'),
            Text(
              'Retiré pour vivre : ${money(taxed.totalWithdrawn)}, soit '
              '${money(taxed.lastMonthlyWithdrawal)} par mois à la fin.',
            ),
            Text(
              taxed.totalTax == 0
                  ? 'Aucun impôt dans ce modèle simplifié.'
                  : '${money(taxed.totalTax)} d’impôts payés au fil des '
                        'ventes et des retraits.',
            ),
            const SizedBox(height: 8),
            Text(profile.explanation),
            const SizedBox(height: 8),
            Text(
              'Chaque impôt et chaque retrait réduit l’argent réinvesti : '
              'l’écart se creuse d’étape en étape. Règles actuelles très '
              'simplifiées, appliquées à toute la période, à titre '
              'd’illustration : ce n’est pas un conseil fiscal.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
