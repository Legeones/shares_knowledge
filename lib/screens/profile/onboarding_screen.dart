import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/birth_year.dart';
import '../../logic/taxes.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/tax_profile_picker.dart';

/// Premier écran au premier démarrage : année de naissance (facultative) et
/// situation fiscale.
class OnboardingScreen extends StatefulWidget {
  final void Function(BuildContext context) onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();

  /// Pays présélectionné d'après la région du téléphone.
  late TaxProfile _profile = context.read<SettingsProvider>().taxProfile(
    defaultCountryCode:
        WidgetsBinding.instance.platformDispatcher.locale.countryCode,
  );

  @override
  void initState() {
    super.initState();
    final year = context.read<SettingsProvider>().birthYear;
    if (year != null) _yearController.text = '$year';
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = context.read<SettingsProvider>();
    await settings.setBirthYear(parseBirthYear(_yearController.text));
    await settings.setTaxProfile(_profile);
    if (mounted) widget.onDone(context);
  }

  @override
  Widget build(BuildContext context) {
    final hero = heroText(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeroPill(child: Icon(Icons.waving_hand_rounded)),
                    const SizedBox(height: 14),
                    Text('Faisons connaissance', style: hero.headlineSmall),
                    const SizedBox(height: 8),
                    const Text(
                      'Deux questions pour personnaliser tes simulations. '
                      'Ces informations restent sur ton téléphone.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const GroupTitle('Ton année de naissance'),
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Année de naissance (facultatif)',
                  helperText:
                      'Pour te montrer la décennie de tes 25 ans dans '
                      'Perfect Foresight.',
                  helperMaxLines: 2,
                ),
                validator: (t) =>
                    validateBirthYear(t, currentYear: DateTime.now().year),
              ),
              const SizedBox(height: 20),
              const GroupTitle('Où paies-tu tes impôts ?'),
              TaxProfilePicker(
                profile: _profile,
                onChanged: (p) => setState(() => _profile = p),
              ),
              const SizedBox(height: 8),
              Text(
                'Pour calculer les impôts sur les gains de tes simulations. '
                'Modifiable à tout moment dans ton profil.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _continue,
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
