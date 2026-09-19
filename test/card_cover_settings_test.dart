import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/backup_codec.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

void main() {
  test('schema 9 migration preserves progress; card visibility survives restart and backup', () async {
    final dir = await Directory.systemTemp.createTemp('guide_card_cover_');
    final file = File('${dir.path}/test.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var r = GoalsRepository(db);
    try {
      await r.saveGoal(title: 'Bestehendes Ziel');
      final id = (await r.load()).goals.single.id;
      await r.saveMilestone(goalId: id, title: 'Schritt', progress: 12.5);
      final milestone = (await r.load()).milestones.single;
      await r.todos.save(
        title: 'Todo',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: milestone.id,
        progressIncrement: 2.5,
      );
      await r.todos.changeCount((await r.load()).todoEntries.single, 1);
      final before = jsonDecode(await r.exportBackup()) as Map<String, dynamic>;
      await db.close();
      final legacy = sqlite.sqlite3.open(file.path);
      legacy.execute('ALTER TABLE goals DROP COLUMN show_card_cover');
      legacy.execute('ALTER TABLE goals DROP COLUMN sort_order');
      legacy.execute('ALTER TABLE milestones DROP COLUMN sort_order');
      legacy.execute('PRAGMA user_version=9');
      legacy.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db);
      expect(jsonDecode(await r.exportBackup()), before);
      expect((await r.load()).goals.single.showCardCover, isTrue);
      expect(
        (await db.customSelect('PRAGMA foreign_key_check').get()),
        isEmpty,
      );
      await r.saveGoal(id: id, title: 'Bestehendes Ziel', showCardCover: false);
      await r.saveGoal(id: id, title: 'Umbenannt');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db);
      expect((await r.load()).goals.single.showCardCover, isFalse);
      expect((await r.load()).milestones.single.progress, 15);
      final backup = await r.exportBackup();
      await r.deleteAllContents();
      await r.importBackup(backup);
      expect(await r.exportBackup(), backup);
      final oldBackup = jsonDecode(backup) as Map<String, dynamic>;
      oldBackup['version'] = 8;
      for (final g in oldBackup['goals'] as List) {
        (g as Map).remove('showCardCover');
      }
      expect(
        BackupCodec.decode(jsonEncode(oldBackup)).goals.single.showCardCover,
        isTrue,
      );
      final invalid = jsonDecode(backup) as Map<String, dynamic>;
      (invalid['goals'] as List).first['showCardCover'] = 'false';
      expect(
        () => BackupCodec.decode(jsonEncode(invalid)),
        throwsA(isA<RuleViolation>()),
      );
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  testWidgets(
    'five emojis fit in one row and target IDs disambiguate identical symbols',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final r = GoalsRepository(db);
      final c = GoalsController(r);
      try {
        for (var i = 0; i < 5; i++) {
          await r.saveGoal(
            title: 'Ziel $i',
            emoji: i < 2 ? '🌿' : ['🌻', '📚', '🧘🏽‍♂️'][i - 2],
          );
          final goal = (await r.load()).goals.last;
          await r.saveMilestone(goalId: goal.id, title: 'Schritt $i');
        }
        await c.load();
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zwischenziele').last);
        await tester.pumpAndSettle();
        final positions = <Offset>[];
        for (final goal in c.snapshot.goals) {
          final button = find.byKey(ValueKey('goal-jump-${goal.id}'));
          expect(button.hitTestable(), findsOneWidget);
          positions.add(tester.getCenter(button));
          expect(find.byTooltip(goal.title), findsOneWidget);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(
            find.text('${goal.emoji} ${goal.title}').hitTestable(),
            findsOneWidget,
          );
        }
        expect(positions.map((p) => p.dy).toSet().length, 1);
        expect(positions.last.dx, lessThan(320));
        expect(find.byType(DropdownButtonFormField<int>), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await db.close();
      }
    },
  );
}
