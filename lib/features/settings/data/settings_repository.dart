import '../../../data/app_database.dart';

enum AppAppearance { system, light, dark }

class SettingsRepository {
  SettingsRepository(this.database);
  final AppDatabase database;

  Future<AppAppearance> loadAppearance() async {
    final row = await database
        .customSelect("SELECT value FROM app_settings WHERE key = 'appearance'")
        .getSingleOrNull();
    final value = row?.read<String>('value');
    return AppAppearance.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppAppearance.system,
    );
  }

  Future<void> saveAppearance(AppAppearance value) => database.customStatement(
    "INSERT INTO app_settings(key,value) VALUES('appearance',?) "
    'ON CONFLICT(key) DO UPDATE SET value=excluded.value',
    [value.name],
  );
}
