/// Espaces insécables du français : « 60 % » ou « réel ? » ne seront jamais
/// coupés en fin de ligne.
String frenchSpaces(String text) => text
    .replaceAllMapped(RegExp(r' ([%:;?!»])'), (m) => ' ${m[1]}')
    .replaceAll('« ', '« ');
