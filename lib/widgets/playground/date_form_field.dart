import 'package:flutter/material.dart';

import '../../core/formatters.dart';

/// Champ de formulaire pour une date, qui ouvre un calendrier au toucher.
class DateFormField extends FormField<DateTime> {
  DateFormField({
    super.key,
    required String label,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onChanged,
    super.validator,
  }) : super(
         initialValue: initialDate,
         builder: (field) {
           Future<void> pick() async {
             final picked = await showDatePicker(
               context: field.context,
               initialDate: field.value ?? lastDate,
               firstDate: firstDate,
               lastDate: lastDate,
             );
             if (picked == null) return; // l'utilisateur a annulé
             final date = DateTime.utc(picked.year, picked.month, picked.day);
             field.didChange(date); // met à jour la valeur du champ
             onChanged(date);
           }

           return InkWell(
             onTap: pick,
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 errorText: field.errorText,
                 suffixIcon: const Icon(Icons.calendar_today),
               ),
               child: Text(field.value == null ? '' : formatDate(field.value!)),
             ),
           );
         },
       );
}
