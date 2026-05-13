import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/database/app_database_provider.dart';
import 'data/seed/default_data.dart';
import 'data/seed/seed_locale_from_platform.dart';
import 'shared/providers/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final db = AppDatabase();
  await seedDefaultData(
    db,
    locale: seedLocaleFromPlatform(
      WidgetsBinding.instance.platformDispatcher.locale,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const SpendHarborApp(),
    ),
  );
}
