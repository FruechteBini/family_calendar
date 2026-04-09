import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/accent_color_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/colors.dart';
import '../features/notes/presentation/note_share_intent_listener.dart';
import '../shared/widgets/toast.dart';
import 'router.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class FamilienkalenderApp extends ConsumerWidget {
  const FamilienkalenderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accentAsync = ref.watch(accentSeedColorProvider);
    final accentSeed = accentAsync.valueOrNull ?? AppColors.primary;
    final theme = AppTheme.dark(accentSeed: accentSeed);

    return NoteShareIntentListener(
      child: MaterialApp.router(
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: 'Familienkalender',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: theme,
        themeMode: themeMode,
        routerConfig: router,
        locale: const Locale('de', 'DE'),
        supportedLocales: const [Locale('de', 'DE')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
