import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/settings/data/settings_repository.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: eigene Einheiten, Messwerte, Beiträge und Neustart', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp('guide_metrics_');
    final file = File('${directory.path}/test.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var r = GoalsRepository(db);
    var c = GoalsController(r);
    try {
      await r.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Wissen & Alltag',
        emoji: '📚',
        color: GoalColor.lavender,
      );
      await r.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Gesundheit',
        emoji: '🌿',
      );
      await r.saveMilestone(
        goalId: 1,
        title: 'Zwölf Bücher lesen',
        motivation: 'Ich möchte neue Perspektiven entdecken und mir Zeit zum Lesen nehmen.',
        scale: const MetricScale(target: 12, unit: 'Bücher'),
        currentValue: 3,
      );
      await r.saveMilestone(
        goalId: 1,
        title: 'Mein Lesefortschritt',
        motivation: 'Jeden Tag ein Stück weiter lesen.',
        scale: const MetricScale(start: 80, target: 300, unit: 'Seiten'),
        currentValue: 135,
      );
      await r.saveMilestone(
        goalId: 1,
        title: 'Eigene Skala ohne Einheit',
        motivation: 'Eine persönliche Gewohnheit sichtbar machen.',
        scale: const MetricScale(target: 10, unit: ''),
        currentValue: 4,
      );
      await r.saveMilestone(
        goalId: 2,
        title: 'Mein Wunschgewicht',
        motivation:
            'Ich möchte mich im Alltag leichter und beweglicher fühlen.',
        scale: const MetricScale(start: 100, target: 80, unit: 'kg'),
        currentValue: 90,
      );
      await r.todos.save(
        title: 'Ein Buch abschließen',
        frequency: TodoFrequency.weekly,
        target: 3,
        milestoneId: 1,
        progressIncrement: 1,
      );
      await r.todos.save(
        title: 'Fortschritt eintragen',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: 4,
        progressIncrement: .5,
      );
      await SettingsRepository(db).saveAppearance(AppAppearance.light);
      await c.load();
      await tester.pumpWidget(GuideApp(controller: c));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      for (final dark in [false, true]) {
        final mode = dark ? 'dark' : 'light';
        if (dark) {
          await tester.tap(find.byTooltip('Einstellungen'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Dunkelmodus'));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Ziele').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Ziel hinzufügen'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('goal-title')),
          'Mehr Zeit für mich',
        );
        await tester.ensureVisible(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        expect(
          find.text('Bitte beschreibe, warum dir dieses Ziel wichtig ist.'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('goal-why')));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('goal-why-$mode-required');
        await tester.enterText(
          find.byKey(const ValueKey('goal-why')),
          'Ich möchte meinen Alltag bewusster gestalten.',
        );
        await tester.ensureVisible(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zwischenziele').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('goal-jump-1')));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('metrics-$mode-overview');
        await tester.tap(find.text('Zwölf Bücher lesen'));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('metrics-$mode-editor-top');
        await tester.ensureVisible(
          find.byKey(const ValueKey('metric-current')),
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot('metrics-$mode-editor-values');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Todos').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Fortschritt eintragen bearbeiten'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('todo-value-increment')),
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot('metrics-$mode-todo-contribution');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(c.snapshot.milestone(4)!.currentValue, 89.5);
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(c.snapshot.milestone(4)!.currentValue, 90);
      }
      final backup = await r.exportBackup();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db);
      c = GoalsController(r);
      expect(await r.exportBackup(), backup);
      await r.deleteAllContents();
      await r.importBackup(backup);
      expect(await r.exportBackup(), backup);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}
