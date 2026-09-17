import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/presentation/goal_editor.dart';

/// Select the supplied test image in Android's document picker when prompted.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: echtes Cover wählen, speichern und wieder öffnen', (
    tester,
  ) async {
    final dir = await Directory.systemTemp.createTemp('guide_native_cover_');
    final file = File('${dir.path}/test.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var controller = GoalsController(GoalsRepository(db));
    try {
      await controller.load();
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ziel hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hintergrundbild auswählen'));
      for (
        var i = 0;
        i < 180 && find.text('Hintergrundbild ändern').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('Hintergrundbild ändern'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('goal-title')),
        'Ruhe finden',
      );
      await tester.enterText(find.byKey(const ValueKey('goal-emoji')), '🧘');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('cover-editor');
      await tester.ensureVisible(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.goals.single.coverImage, isNotNull);
      expect(controller.snapshot.goals.single.emoji, '🧘');
      final backup = await controller.repository.exportBackup();
      await tester.tap(find.text('Ruhe finden'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('cover-detail');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      controller = GoalsController(GoalsRepository(db));
      await controller.load();
      expect(await controller.repository.exportBackup(), backup);
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ruhe finden'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ziel bearbeiten'));
      await tester.pumpAndSettle();
      expect(find.byType(GoalEditor), findsOneWidget);
      await tester.tap(find.byTooltip('Hintergrundbild entfernen'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.goals.single.coverImage, isNull);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await db.close();
      await dir.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
