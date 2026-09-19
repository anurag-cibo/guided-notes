import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/settings/application/settings_controller.dart';
import 'package:guided_notes/features/settings/data/settings_repository.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

import 'fixtures/legacy_todos.dart';

void main() {
  test(
    'v2 migration preserves all content; appearance survives database reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'guide_settings_',
      );
      final file = File('${directory.path}/store.sqlite');
      final fixedNow = DateTime(2026, 9, 18, 12);
      var db = AppDatabase(NativeDatabase(file));
      try {
        final goals = GoalsRepository(db, now: () => fixedNow);
        await goals.saveGoal(
          motivation: 'Meine persönliche Richtung',
          title: 'Bleibt erhalten',
        );
        await goals.todos.save(
          title: 'Lesen',
          frequency: TodoFrequency.daily,
          target: 1,
        );
        final before = await goals.exportBackup();
        await db.close();
        // Schema 2 is identical except that app_settings does not exist.
        final legacy = sqlite.sqlite3.open(file.path);
        legacy.execute('DROP TABLE app_settings');
        legacy.execute('ALTER TABLE goals DROP COLUMN cover_image');
        legacy.execute('ALTER TABLE goals DROP COLUMN color');
        legacy.execute('ALTER TABLE goals DROP COLUMN custom_theme_id');
        legacy.execute('DROP TABLE goal_themes');
        removeTodoLinks(legacy);
        legacy.execute('ALTER TABLE goals DROP COLUMN started_on');
        legacy.execute('PRAGMA user_version = 2');
        legacy.close();
        db = AppDatabase(NativeDatabase(file));
        var settings = SettingsRepository(db);
        expect(await settings.loadAppearance(), AppAppearance.system);
        expect(
          await GoalsRepository(db, now: () => fixedNow).exportBackup(),
          before,
        );
        await settings.saveAppearance(AppAppearance.dark);
        await db.close();
        db = AppDatabase(NativeDatabase(file));
        settings = SettingsRepository(db);
        expect(await settings.loadAppearance(), AppAppearance.dark);
        expect(
          await GoalsRepository(db, now: () => fixedNow).exportBackup(),
          before,
        );
        await db.customStatement("UPDATE app_settings SET value='future-mode'");
        expect(await settings.loadAppearance(), AppAppearance.system);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'delete all is atomic and preserves settings; backup restores contents',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final goals = GoalsRepository(db);
        await goals.saveGoal(
          motivation: 'Meine persönliche Richtung',
          title: 'Gesundheit',
        );
        final id = (await goals.load()).goals.single.id;
        await goals.saveMilestone(
          motivation: 'Mein nächster Schritt zum Ziel',
          goalId: id,
          title: 'Bewegen',
        );
        await goals.todos.save(
          title: 'Lesen',
          frequency: TodoFrequency.daily,
          target: 1,
        );
        await SettingsRepository(db).saveAppearance(AppAppearance.dark);
        final before = await goals.exportBackup();
        await db.customStatement(
          "CREATE TRIGGER fail_delete BEFORE DELETE ON goals BEGIN SELECT RAISE(ABORT, 'test'); END",
        );
        await expectLater(goals.deleteAllContents(), throwsA(anything));
        expect(await goals.exportBackup(), before);
        await db.customStatement('DROP TRIGGER fail_delete');
        await goals.deleteAllContents();
        expect((await goals.load()).isEmpty, isTrue);
        expect(
          await SettingsRepository(db).loadAppearance(),
          AppAppearance.dark,
        );
        await goals.importBackup(before);
        expect(await goals.exportBackup(), before);
      } finally {
        await db.close();
      }
    },
  );

  test('failed setting write retains the selected appearance', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final c = SettingsController(SettingsRepository(db));
    try {
      await c.load();
      await db.customStatement(
        "CREATE TRIGGER fail_setting BEFORE INSERT ON app_settings BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await c.setAppearance(AppAppearance.dark);
      expect(c.appearance, AppAppearance.system);
      expect(c.error, isNotNull);
      expect(c.saving, isFalse);
    } finally {
      c.dispose();
      await db.close();
    }
  });

  testWidgets(
    'settings changes theme, follows system, confirms deletion and fits large text',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final goals = GoalsController(GoalsRepository(db));
      await goals.repository.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Mein Ziel',
      );
      await goals.load();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      try {
        await tester.pumpWidget(GuideApp(controller: goals));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Einstellungen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dunkelmodus'));
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.text('Dunkelmodus'))).brightness,
          Brightness.dark,
        );
        expect(
          await SettingsRepository(db).loadAppearance(),
          AppAppearance.dark,
        );
        await tester.tap(find.text('Hellmodus'));
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.text('Hellmodus'))).brightness,
          Brightness.light,
        );
        await tester.tap(find.text('Wie das Gerät'));
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.text('Wie das Gerät'))).brightness,
          Brightness.dark,
        );
        await tester.scrollUntilVisible(find.text('Alle Inhalte löschen'), 250);
        await tester.ensureVisible(find.text('Alle Inhalte löschen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alle Inhalte löschen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();
        expect(goals.snapshot.goals, hasLength(1));
        await tester.ensureVisible(find.text('Alle Inhalte löschen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alle Inhalte löschen'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Alle Inhalte löschen'),
        );
        await tester.pumpAndSettle();
        expect(goals.snapshot.isEmpty, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        goals.dispose();
        await db.close();
      }
    },
  );
}
