import 'package:flutter/material.dart';

import '../logic/taxes.dart';

/// Choix de la situation fiscale : pays, État (États-Unis), revenus.
class TaxProfilePicker extends StatelessWidget {
  final TaxProfile profile;
  final ValueChanged<TaxProfile> onChanged;

  /// Faux : les revenus sont imposés par l'écran (ex. Perfect Foresight,
  /// où des gains de plusieurs millions supposent des revenus élevés).
  final bool showIncome;

  const TaxProfilePicker({
    super.key,
    required this.profile,
    required this.onChanged,
    this.showIncome = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<TaxCountry>(
          initialValue: profile.country,
          isExpanded:
              true, // le texte s'adapte à la largeur au lieu de déborder
          decoration: const InputDecoration(
            labelText: 'Pays de résidence fiscale',
          ),
          items: [
            for (final c in taxCountries)
              DropdownMenuItem(value: c, child: Text(c.name)),
          ],
          onChanged: (c) {
            if (c != null) {
              onChanged(TaxProfile(c, income: profile.income));
            }
          },
        ),
        if (profile.country.hasStates) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<UsState?>(
            // La clé change avec le pays : le champ repart de « aucun État ».
            key: ValueKey(profile.country.code),
            initialValue: profile.state,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'État'),
            items: [
              const DropdownMenuItem<UsState?>(
                value: null,
                child: Text('Impôt fédéral seulement'),
              ),
              for (final s in usStates)
                DropdownMenuItem<UsState?>(value: s, child: Text(s.name)),
            ],
            onChanged: (s) => onChanged(
              TaxProfile(profile.country, state: s, income: profile.income),
            ),
          ),
        ],
        if (showIncome && profile.country.dependsOnIncome) ...[
          const SizedBox(height: 12),
          Text(
            'Revenus du foyer',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          SegmentedButton<IncomeLevel>(
            segments: [
              for (final i in IncomeLevel.values)
                ButtonSegment(value: i, label: Text(i.label)),
            ],
            selected: {profile.income},
            onSelectionChanged: (s) => onChanged(
              TaxProfile(
                profile.country,
                state: profile.state,
                income: s.first,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
