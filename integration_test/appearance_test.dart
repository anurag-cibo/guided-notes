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
  testWidgets(
    'Android: Darstellung, Screens und Neustart mit separaten Testdaten',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'guide_appearance_',
      );
      final file = File('${directory.path}/test.sqlite');
      var database = AppDatabase(NativeDatabase(file));
      var controller = GoalsController(GoalsRepository(database));
      try {
        final r = controller.repository;
        await r.saveGoal(
          title: 'Gesundheit',
          emoji: '🌿',
          motivation: 'Mehr Energie. Mehr Lebensqualität. Ich möchte mich in meinem Körper wohlfühlen.',
        );
        final id = (await r.load()).goals.single.id;
        await r.saveMilestone(
          goalId: id,
          title: 'Regelmäßig bewegen',
          progress: 60,
          status: MilestoneStatus.onTrack,
        );
        await r.saveMilestone(
          goalId: id,
          title: 'Bewusst essen',
          progress: 30,
          status: MilestoneStatus.offTrack,
        );
        await r.saveMilestone(goalId: id, title: 'Erholsam schlafen');
        await r.saveGoal(title: 'Beruf & Karriere', emoji: '💻');
        await r.saveGoal(title: 'Finanzen', emoji: '💰');
        await r.saveGoal(title: 'Beziehungen', emoji: '❤️');
        await r.todos.save(
          title: 'Wasser trinken',
          frequency: TodoFrequency.daily,
          target: 1,
        );
        await r.todos.save(
          title: 'Zehn Minuten lesen',
          frequency: TodoFrequency.daily,
          target: 1,
        );
        await r.todos.save(
          title: 'Sport',
          frequency: TodoFrequency.weekly,
          target: 3,
        );
        await SettingsRepository(database).saveAppearance(AppAppearance.light);
        await controller.load();
        await tester.pumpWidget(GuideApp(controller: controller));
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
          await binding.takeScreenshot('appearance-$mode-goals');
          await tester.tap(find.text('Gesundheit'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-detail');
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Zwischenziele').last);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-milestones');
          await tester.tap(find.text('Todos').last);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-todos');
          await tester.tap(find.byTooltip('Einstellungen'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-settings');
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ziele').last);
          await tester.pumpAndSettle();
        }
        final backup = await r.exportBackup();
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        await database.close();
        database = AppDatabase(NativeDatabase(file));
        controller = GoalsController(GoalsRepository(database));
        await controller.load();
        expect(
          await SettingsRepository(database).loadAppearance(),
          AppAppearance.dark,
        );
        expect(await controller.repository.exportBackup(), backup);
        await tester.pumpWidget(GuideApp(controller: controller));
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.text('Gesundheit'))).brightness,
          Brightness.dark,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
