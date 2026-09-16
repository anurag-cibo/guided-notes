import 'package:flutter/foundation.dart';

import '../data/goals_repository.dart';
import '../domain/models.dart';

class GoalsController extends ChangeNotifier {
  GoalsController(this.repository);
  final GoalsRepository repository;
  GoalSnapshot snapshot = GoalSnapshot([], []);
  bool loading = true;
  bool saving = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      snapshot = await repository.load();
    } catch (_) {
      error = 'Die gespeicherten Ziele konnten nicht geladen werden. Bitte erneut versuchen.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// One UI mutation at a time; the database enforces invariants independently.
  Future<String?> mutate(Future<void> Function(GoalsRepository) action) async {
    if (saving) return 'Bitte kurz warten, die Änderung wird gespeichert.';
    saving = true;
    notifyListeners();
    try {
      await action(repository);
      snapshot = await repository.load();
      return null;
    } on RuleViolation catch (e) {
      return e.message;
    } catch (_) {
      return 'Die Änderung konnte nicht bestätigt werden. Bitte erneut laden und prüfen.';
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
