import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/preferences/calendar_defaults.dart';
import '../../categories/categories_providers.dart';
import '../../../shared/widgets/category_picker.dart';
import '../../../shared/widgets/toast.dart';

/// Default calendar category (color) for personal vs family-wide events.
class SettingsCalendarDefaultsScreen extends ConsumerWidget {
  const SettingsCalendarDefaultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final defsAsync = ref.watch(calendarDefaultsProvider);
    final catsAsync = ref.watch(familyTodoCategoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalenderfarben')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Die Farbe im Kalender kommt von der Kategorie. Hier legst du fest, '
            'welche Kategorie bei neuen Terminen vorgewählt wird — abhängig davon, '
            'ob der Termin nur dich oder die ganze Familie betrifft.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          if (!auth.hasFamilyId)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tritt einer Familie bei oder lege eine an, um Kalenderfarben zu nutzen.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            catsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Fehler: $e'),
              data: (categories) {
                if (categories.isEmpty) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: const Text('Noch keine Kategorien'),
                      subtitle: const Text(
                        'Lege unter Einstellungen → Todos → Kategorien mindestens eine Kategorie an.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/categories'),
                    ),
                  );
                }
                return defsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Fehler: $e'),
                  data: (defs) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CategoryPicker(
                        categories: categories,
                        selectedId: defs.personalCalendarCategoryId,
                        labelText: 'Nur für mich',
                        hintText:
                            'Vorgabe, wenn nur du als Mitglied ausgewählt bist',
                        onChanged: (id) async {
                          try {
                            await ref
                                .read(calendarDefaultsProvider.notifier)
                                .setPersonalCalendarCategoryId(id);
                          } on Object catch (e) {
                            if (context.mounted) {
                              showAppToast(
                                context,
                                message: '$e',
                                type: ToastType.error,
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      CategoryPicker(
                        categories: categories,
                        selectedId: defs.familyDefaultCalendarCategoryId,
                        labelText: 'Familie',
                        hintText:
                            'Vorgabe für alle anderen Fälle (mehrere Personen oder niemand gewählt)',
                        onChanged: (id) async {
                          try {
                            await ref
                                .read(calendarDefaultsProvider.notifier)
                                .setFamilyDefaultCalendarCategoryId(id);
                          } on Object catch (e) {
                            if (context.mounted) {
                              showAppToast(
                                context,
                                message: '$e',
                                type: ToastType.error,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
