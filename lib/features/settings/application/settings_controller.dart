import 'package:flutter/foundation.dart';

import '../data/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this.repository);
  final SettingsRepository repository;
  AppAppearance appearance = AppAppearance.light;
  bool loading = true;
  bool saving = false;
  String? error;
  bool _disposed = false;

  Future<void> load({bool startLight = false}) async {
    loading = true;
    error = null;
    _notify();
    try {
      appearance = startLight
          ? AppAppearance.light
          : await repository.loadAppearance();
    } catch (_) {
      error = 'Die Darstellung konnte nicht geladen werden.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> setAppearance(AppAppearance value) async {
    if (loading || saving) return;
    saving = true;
    error = null;
    _notify();
    try {
      await repository.saveAppearance(value);
      appearance = value;
    } catch (_) {
      error = 'Die Darstellung konnte nicht gespeichert werden. Bitte erneut versuchen.';
    } finally {
      saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
