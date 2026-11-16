import 'package:flutter/material.dart';

/// Boîtes de dialogue réutilisées par plusieurs écrans.
///
/// `showDialog` renvoie un Future qui se termine quand la boîte se ferme,
/// avec la valeur passée à Navigator.pop (null si l'utilisateur annule).

/// Demande un texte (nom d'une sauvegarde, pseudo…). null = annulé.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
  String confirmLabel = 'Enregistrer',
  bool allowEmpty = false,
  FormFieldValidator<String>? validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: title,
      label: label,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      allowEmpty: allowEmpty,
      validator: validator,
    ),
  );
}

/// La boîte de saisie est un StatefulWidget pour posséder son
/// TextEditingController et le libérer dans dispose(), c'est-à-dire
/// seulement quand la boîte a fini de disparaître (animation comprise).
class _TextDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final String confirmLabel;
  final bool allowEmpty;

  /// Vérification supplémentaire (ex. une année valide).
  final FormFieldValidator<String>? validator;

  const _TextDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.confirmLabel,
    required this.allowEmpty,
    this.validator,
  });

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 60,
          decoration: InputDecoration(labelText: widget.label),
          validator: (text) => !widget.allowEmpty && (text ?? '').trim().isEmpty
              ? 'Ce champ ne peut pas être vide.'
              : widget.validator?.call(text),
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// Demande une confirmation explicite avant une action irréversible.
/// Renvoie true seulement si l'utilisateur confirme.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false; // fermée en touchant à côté = pas de confirmation
}
