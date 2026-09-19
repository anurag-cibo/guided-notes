import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/cover_image.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';

import 'fixtures/legacy_todos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List picture;
  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(const Color(0xff187c68), BlendMode.src);
    final drawing = recorder.endRecording();
    final image = await drawing.toImage(20, 10);
    picture = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
    drawing.dispose();
  });

  testWidgets(
    'goal card clips cover above progress and updates at large text',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final r = GoalsRepository(db);
      final c = GoalsController(r);
      await tester.runAsync(
        () => r.saveGoal(
          title: 'Ein langes persönliches Ziel mit vielen kleinen Schritten',
          coverImage: picture,
        ),
      );
      final id = (await r.load()).goals.single.id;
      await r.saveMilestone(goalId: id, title: 'Schritt', progress: 35);
      await c.load();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(GuideApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(Image)).dy,
        lessThan(tester.getTopLeft(find.byType(LinearProgressIndicator)).dy),
      );
      expect(find.text('35 %'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await r.saveGoal(id: id, title: 'Ohne Bild', removeCoverImage: true);
      await c.load();
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      await tester.runAsync(
        () => r.saveGoal(id: id, title: 'Wieder mit Bild', coverImage: picture),
      );
      await c.load();
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
    },
  );

  test(
    'v3 migration, image restart, backup, removal and deletion preserve data',
    () async {
      final dir = await Directory.systemTemp.createTemp('guide_cover_');
      final file = File('${dir.path}/data.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      try {
        await GoalsRepository(db).saveGoal(title: 'Vorher');
        await db.close();
        final old = sqlite.sqlite3.open(file.path);
        old.execute('ALTER TABLE goals DROP COLUMN cover_image');
        removeTodoLinks(old);
        old.execute('ALTER TABLE goals DROP COLUMN started_on');
        old.execute('PRAGMA user_version = 3');
        old.execute('ALTER TABLE goals DROP COLUMN color');
        old.execute('ALTER TABLE goals DROP COLUMN custom_theme_id');
        old.execute('DROP TABLE goal_themes');
        old.close();
        db = AppDatabase(NativeDatabase(file));
        var repo = GoalsRepository(db);
        final goal = (await repo.load()).goals.single;
        expect(goal.title, 'Vorher');
        expect(goal.coverImage, isNull);
        await repo.saveGoal(
          id: goal.id,
          title: 'Mit Bild',
          emoji: '🧘🏽‍♂️',
          coverImage: picture,
        );
        await db.close();
        db = AppDatabase(NativeDatabase(file));
        repo = GoalsRepository(db);
        expect((await repo.load()).goals.single.coverImage, picture);
        await repo.saveGoal(id: goal.id, title: 'Bild bleibt');
        expect((await repo.load()).goals.single.coverImage, picture);
        final backup = await repo.exportBackup();
        await repo.deleteAllContents();
        await repo.importBackup(backup);
        expect((await repo.load()).goals.single.coverImage, picture);
        await repo.saveGoal(
          id: goal.id,
          title: 'Ohne Bild',
          removeCoverImage: true,
        );
        expect((await repo.load()).goals.single.coverImage, isNull);
        await repo.saveGoal(id: goal.id, title: 'Löschen', coverImage: picture);
        await repo.setArchived(goal.id, true);
        await repo.deleteGoal(goal.id);
        expect((await repo.load()).isEmpty, isTrue);
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'invalid images and multiple emoji are rejected without changing content',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repo = GoalsRepository(db);
        await repo.saveGoal(
          title: 'Bleibt',
          emoji: '🇩🇪',
          coverImage: picture,
        );
        final goal = (await repo.load()).goals.single;
        await expectLater(
          repo.saveGoal(id: goal.id, title: 'Fehler', emoji: 'ab'),
          throwsA(isA<RuleViolation>()),
        );
        await expectLater(
          repo.saveGoal(
            id: goal.id,
            title: 'Fehler',
            coverImage: Uint8List.fromList([1, 2, 3]),
          ),
          throwsA(isA<RuleViolation>()),
        );
        expect((await repo.load()).goals.single.title, 'Bleibt');
        expect((await repo.load()).goals.single.coverImage, picture);
        final invalid =
            jsonDecode(await repo.exportBackup()) as Map<String, dynamic>;
        (invalid['goals'] as List).first['coverImage'] = base64Encode([
          1,
          2,
          3,
        ]);
        await repo.deleteAllContents();
        await expectLater(
          repo.importBackup(jsonEncode(invalid)),
          throwsA(isA<RuleViolation>()),
        );
        expect((await repo.load()).isEmpty, isTrue);
        invalid['version'] = 2;
        await repo.importBackup(jsonEncode(invalid));
        expect((await repo.load()).goals.single.coverImage, isNull);
      } finally {
        await db.close();
      }
    },
  );

  testWidgets('cover selection and cancellation, single grapheme and save', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = GoalsController(GoalsRepository(db));
    Uint8List? selected;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      CoverImages.channel,
      (_) async => selected,
    );
    try {
      await controller.load();
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ziel hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hintergrundbild auswählen'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Hintergrundbild entfernen'), findsNothing);
      selected = picture;
      await tester.runAsync(() async {
        await tester.tap(find.text('Hintergrundbild auswählen'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byTooltip('Hintergrundbild entfernen'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('goal-emoji')),
        '🧘🏽‍♂️🌿',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('goal-emoji')))
            .controller!
            .text,
        '🧘🏽‍♂️',
      );
      await tester.enterText(
        find.byKey(const ValueKey('goal-title')),
        'Ruhe finden',
      );
      await tester.scrollUntilVisible(
        find.text('Speichern'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Speichern'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(controller.snapshot.goals.single.coverImage, picture);
      expect(controller.snapshot.goals.single.emoji, '🧘🏽‍♂️');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        CoverImages.channel,
        null,
      );
      controller.dispose();
      await db.close();
    }
  });
}
