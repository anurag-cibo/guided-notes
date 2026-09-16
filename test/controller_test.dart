import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';

void main() {
  test('failed load is visible and retry can recover', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = _FailingRepository(database);
    final controller = GoalsController(repository);
    await controller.load();
    expect(controller.loading, isFalse);
    expect(controller.error, contains('nicht geladen'));
    repository.fail = false;
    await controller.load();
    expect(controller.error, isNull);
    controller.dispose();
    await database.close();
  });

  test('write failure and double save never silently succeed', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final controller = GoalsController(GoalsRepository(database));
    await controller.load();
    final error = await controller.mutate(
      (_) => Future.error(StateError('disk full')),
    );
    expect(error, contains('nicht bestätigt'));
    expect(controller.snapshot.goals, isEmpty);
    expect(controller.saving, isFalse);
    final gate = Completer<void>();
    final first = controller.mutate((r) async {
      await gate.future;
      await r.saveGoal(title: 'Einmal');
    });
    expect(
      await controller.mutate((r) => r.saveGoal(title: 'Doppelt')),
      contains('Bitte kurz warten'),
    );
    gate.complete();
    expect(await first, isNull);
    expect(controller.snapshot.goals.single.title, 'Einmal');
    controller.dispose();
    await database.close();
  });
}

class _FailingRepository extends GoalsRepository {
  _FailingRepository(super.database);
  bool fail = true;
  @override
  load() {
    if (fail) return Future.error(StateError('unavailable'));
    return super.load();
  }
}
