import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

void main() {
  testWidgets(
    'todos create, check, undo, edit, roll over and back navigation',
    (tester) async {
      var now = DateTime(2026, 9, 20, 23, 59);
      final database = AppDatabase(NativeDatabase.memory());
      final controller = GoalsController(
        GoalsRepository(database, now: () => now),
      );
      addTearDown(() async {
        controller.dispose();
        await database.close();
      });
      await controller.load();
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('20.9.'), findsOneWidget);
      expect(find.text('14.–20.9.'), findsOneWidget);
      expect(
        tester.getCenter(find.text('20.9.')).dy,
        tester.getCenter(find.text('Heute')).dy,
      );
      await tester.tap(find.byTooltip('Tagesaufgabe hinzufügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Lesen');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.snapshot.todoEntries.single.completed, 1);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.snapshot.todoEntries.single.completed, 0);
      await tester.ensureVisible(find.byTooltip('Wochenaufgabe hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Wochenaufgabe hinzufügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Laufen');
      await tester.enterText(find.byType(TextFormField).last, '2');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Laufen: einmal erledigt'));
      await tester.tap(find.byTooltip('Laufen: einmal erledigt'));
      await tester.pumpAndSettle();
      expect(find.text('1 von 2'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.5,
      );
      await tester.tap(find.byTooltip('Laufen: einmal rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('0 von 2'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
      await tester.tap(find.byTooltip('Laufen bearbeiten'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Joggen');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Laufen'), findsOneWidget);
      now = DateTime(2026, 9, 21);
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(find.text('Joggen'), findsOneWidget);
      expect(controller.snapshot.todoEntries, hasLength(4));
      await tester.ensureVisible(find.text('Vergangene Zeiträume'));
      await tester.tap(find.text('Vergangene Zeiträume'));
      await tester.pumpAndSettle();
      expect(find.text('Laufen'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Ziele'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'todos with long names fit large text and stopping needs confirmation',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final controller = GoalsController(GoalsRepository(database));
      addTearDown(() async {
        controller.dispose();
        await database.close();
      });
      const title = 'Ein langer Aufgabenname für meine tägliche Leseroutine';
      await controller.repository.todos.save(
        title: title,
        frequency: TodoFrequency.daily,
        target: 1,
      );
      await controller.load();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byTooltip('$title bearbeiten'), 250);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('$title bearbeiten'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Aufgabe beenden'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aufgabe beenden'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.todoTemplates.single.active, isTrue);
      await tester.tap(find.text('Aufgabe beenden'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beenden'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.todoTemplates.single.active, isFalse);
      expect(controller.snapshot.todoEntries, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
