import 'package:flutter/foundation.dart';

import '../data/goals_repository.dart';
import '../domain/models.dart';
import '../../todos/domain/todo_models.dart';

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
      error = 'Die gespeicherten Inhalte konnten nicht geladen werden. Bitte erneut versuchen.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// One UI mutation at a time; the database enforces invariants independently.
  Future<String?> mutate(Future<void> Function(GoalsRepository) action) =>
      _mutate(() async {
        await action(repository);
        return repository.load();
      });

  Future<String?> changeTodoCount(TodoEntry entry, int delta) =>
      _mutate(() => repository.changeTodoCount(snapshot, entry, delta));

  Future<String?> _mutate(Future<GoalSnapshot> Function() update) async {
    if (saving) return 'Bitte kurz warten, die Änderung wird gespeichert.';
    saving = true;
    // The lock protects writes, but is not a visual loading state. Publishing it
    // would briefly disable every checkbox/button and rebuild the screen twice.
    try {
      snapshot = await update();
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
