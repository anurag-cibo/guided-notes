import 'dart:io';
import 'dart:ui' as ui;

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
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(const Color(0xfff4e9be), BlendMode.src);
        for (var x = 0; x < 600; x += 45) {
          canvas.drawCircle(
            Offset(x.toDouble(), 110),
            70,
            Paint()
              ..color = x.isEven
                  ? const Color(0xff396d56)
                  : const Color(0xffd7bb72),
          );
        }
        final drawing = recorder.endRecording();
        final image = await drawing.toImage(600, 300);
        final cover = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
        image.dispose();
        drawing.dispose();
        final customThemeId = await r.saveTheme(
          name: 'Abend am Meer',
          colors: const ThemeColors(
            primary: 0xff286eaa,
            secondary: 0xff347d82,
            accent: 0xffaa536c,
            surface: 0xff417db8,
          ),
        );
        await r.saveGoal(
          title: 'Gesundheit',
          coverImage: cover,
          dueDate: DateTime.now().add(const Duration(days: 45)),
          emoji: '🌿',
          color: GoalColor.ocean,
          customThemeId: customThemeId,
          motivation: 'Mehr Energie. Mehr Lebensqualität. Ich möchte mich in meinem Körper wohlfühlen.',
        );
        final id = (await r.load()).goals.single.id;
        await r.saveMilestone(
          goalId: id,
          title: 'Regelmäßig bewegen',
          progress: 60,
          status: MilestoneStatus.onTrack,
          dueDate: DateTime.now().add(const Duration(days: 30)),
        );
        await r.saveMilestone(
          goalId: id,
          title: 'Bewusst essen',
          progress: 30,
          status: MilestoneStatus.offTrack,
        );
        await r.saveMilestone(goalId: id, title: 'Erholsam schlafen');
        await r.saveGoal(
          title: 'Beruf & Karriere',
          emoji: '💻',
          color: GoalColor.lavender,
        );
        await r.saveGoal(
          title: 'Finanzen',
          emoji: '💰',
          color: GoalColor.amber,
        );
        await r.saveGoal(
          title: 'Beziehungen',
          emoji: '❤️',
          color: GoalColor.rose,
        );
        await r.todos.save(
          title: 'Wasser trinken',
          frequency: TodoFrequency.daily,
          target: 1,
          milestoneId: (await r.load()).milestones.first.id,
          progressIncrement: 2.5,
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
          milestoneId: (await r.load()).milestones.first.id,
          progressIncrement: 2.5,
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
          await tester.scrollUntilVisible(find.text('Ziel archivieren'), 200);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-actions');
          await tester.tap(find.byTooltip('Ziel bearbeiten'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-editor');
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Zwischenziele').last);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-milestones');
          await tester.tap(find.text('Regelmäßig bewegen'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-milestone-editor');
          await tester.ensureVisible(find.byTooltip('Sport: einmal erledigt'));
          await tester.tap(find.byTooltip('Sport: einmal erledigt'));
          await tester.pumpAndSettle();
          expect(controller.snapshot.milestones.first.progress, 62.5);
          await tester.tap(find.byTooltip('Sport: einmal rückgängig'));
          await tester.pumpAndSettle();
          expect(controller.snapshot.milestones.first.progress, 60);
          await binding.takeScreenshot('appearance-$mode-milestone-todos');
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Todos').last);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-todos');
          await tester.ensureVisible(find.byTooltip('Sport: einmal erledigt'));
          await tester.tap(find.byTooltip('Sport: einmal erledigt'));
          await tester.pumpAndSettle();
          expect(controller.snapshot.milestones.first.progress, 62.5);
          await tester.tap(find.byTooltip('Sport: einmal rückgängig'));
          await tester.pumpAndSettle();
          expect(controller.snapshot.milestones.first.progress, 60);
          await tester.tap(find.byTooltip('Sport bearbeiten'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-todo-editor');
          await tester.tap(find.byKey(const ValueKey('todo-milestone')));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-todo-links');
          await tester.tap(find.text('Regelmäßig bewegen'));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Einstellungen'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-settings');
          await tester.tap(find.text('Themes'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-themes');
          await tester.tap(find.text('Abend am Meer'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('appearance-$mode-theme-editor');
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ziele').last);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Todos'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Sport bearbeiten'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byType(DropdownButtonFormField<TodoProgressMode>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bei vollständiger Wochenaufgabe').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Speichern'));
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        for (var i = 1; i <= 3; i++) {
          await tester.ensureVisible(find.byTooltip('Sport: einmal erledigt'));
          await tester.tap(find.byTooltip('Sport: einmal erledigt'));
          await tester.pumpAndSettle();
          expect(
            controller.snapshot.milestones.first.progress,
            i == 3 ? 62.5 : 60,
          );
        }
        await tester.tap(find.byTooltip('Sport: einmal rückgängig'));
        await tester.pumpAndSettle();
        expect(controller.snapshot.milestones.first.progress, 60);
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
