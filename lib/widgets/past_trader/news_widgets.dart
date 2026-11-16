import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/past_trader/news.dart';

const _categoryIcons = {
  NewsCategory.politique: Icons.account_balance_outlined,
  NewsCategory.economie: Icons.trending_up,
  NewsCategory.banqueCentrale: Icons.savings_outlined,
  NewsCategory.entreprise: Icons.business_outlined,
  NewsCategory.crypto: Icons.currency_bitcoin,
  NewsCategory.geopolitique: Icons.public,
  NewsCategory.sante: Icons.medical_services_outlined,
};

/// Une actualité dans une liste.
class NewsTile extends StatelessWidget {
  final NewsItem item;
  const NewsTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _categoryIcons[item.category],
            color: item.major ? AppColors.loss : AppColors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatDate(item.date)} · ${item.category.label}'
                  '${item.major ? ' · À la une' : ''}',
                  style: textTheme.labelSmall,
                ),
                Text(item.title, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(item.body, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « Flash info » : les actualités majeures tombées pendant l'avancée du
/// temps. La lecture automatique est en pause pendant l'affichage.
Future<void> showFlashNews(BuildContext context, List<NewsItem> items) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.campaign_outlined, color: AppColors.loss),
                const SizedBox(width: 8),
                Text(
                  'Flash info',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [for (final n in items) NewsTile(item: n)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.pop(sheetContext),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('Reprendre'),
            ),
          ),
        ],
      ),
    ),
  );
}
