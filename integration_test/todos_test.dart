import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: Todos abhaken und nach Datenbank-Neustart erhalten', (
    tester,
  ) async {
    // A separate temporary database keeps real app data untouched.
    final directory = await Directory.systemTemp.createTemp(
      'guide_todos_device_',
    );
    final file = File('${directory.path}/todos.sqlite');
    var database = AppDatabase(NativeDatabase(file));
    var controller = GoalsController(GoalsRepository(database));
    try {
      await controller.load();
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tagesaufgabe hinzufügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Zehn Minuten lesen');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.snapshot.todoEntries.single.completed, 1);
      await tester.ensureVisible(find.byTooltip('Wochenaufgabe hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Wochenaufgabe hinzufügen'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Spazieren gehen',
      );
      await tester.enterText(find.byType(TextFormField).last, '3');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byTooltip('Spazieren gehen: einmal erledigt'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Spazieren gehen: einmal erledigt'));
      await tester.pumpAndSettle();
      expect(find.text('1 von 3 erledigt'), findsOneWidget);
      final backup = await controller.repository.exportBackup();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      controller = GoalsController(GoalsRepository(database));
      await controller.load();
      expect(await controller.repository.exportBackup(), backup);
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.ensureVisible(
        find.byTooltip('Spazieren gehen: einmal rückgängig'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Spazieren gehen: einmal rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('0 von 3 erledigt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
