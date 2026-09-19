import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/milestone_editor.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';
import 'package:guided_notes/features/todos/presentation/todos_view.dart';
import 'package:guided_notes/theme/guide_theme.dart';

void main() {
  testWidgets(
    'linked todos share counts, create with link and preserve progress drafts',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repository = GoalsRepository(db, now: () => DateTime(2026, 9, 19));
      final controller = GoalsController(repository);
      await repository.saveGoal(title: 'Gesundheit');
      final goal = (await repository.load()).goals.single;
      await repository.saveMilestone(
        goalId: goal.id,
        title: 'Bewegen',
        progress: 20,
        status: MilestoneStatus.onTrack,
        dueDate: DateTime(2026, 10, 1),
      );
      final milestone = (await repository.load()).milestones.single;
      await repository.todos.save(
        title: 'Spaziergang',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: milestone.id,
        progressIncrement: 2.5,
      );
      await repository.todos.save(
        title: 'Sport',
        frequency: TodoFrequency.weekly,
        target: 3,
        milestoneId: milestone.id,
        progressIncrement: 1,
      );
      await repository.todos.save(
        title: 'Unabhängig',
        frequency: TodoFrequency.daily,
        target: 1,
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: guideTheme(Brightness.light),
          locale: const Locale('de'),
          supportedLocales: const [Locale('de')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MilestoneEditor(
                          controller: controller,
                          goal: goal,
                          milestone: controller.snapshot.milestones.single,
                        ),
                      ),
                    ),
                    child: const Text('Öffnen'),
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (_, _) => TodosView(controller: controller),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      expect(find.text('Unabhängig'), findsNothing);
      expect(
        tester
            .getTopLeft(find.byType(DropdownButtonFormField<MilestoneStatus>))
            .dy,
        closeTo(
          tester.getTopLeft(find.widgetWithText(InputDecorator, 'Frist')).dy,
          2,
        ),
      );
      await tester.enterText(
        find.byType(TextFormField),
        'Bewegen und entspannen',
      );
      tester.widget<Slider>(find.byType(Slider)).onChanged!(30);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.snapshot.milestones.single.progress, 32.5);
      expect(
        controller.snapshot.milestones.single.title,
        'Bewegen und entspannen',
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.snapshot.milestones.single.progress, 30);
      await tester.ensureVisible(find.byTooltip('Sport: einmal erledigt'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sport: einmal erledigt'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.milestones.single.progress, 31);
      await tester.ensureVisible(find.byTooltip('Tagesaufgabe hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tagesaufgabe hinzufügen'));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text('Gesundheit · Bewegen und entspannen'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Dehnen');
      await tester.ensureVisible(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      final added = controller.snapshot.todoTemplates.singleWhere(
        (t) => t.title == 'Dehnen',
      );
      expect(added.milestoneId, milestone.id);
      expect(added.progressIncrement, 2.5);
      await tester.ensureVisible(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.milestones.single.progress, 31);
      expect(find.text('Dehnen'), findsOneWidget);
      expect(find.text('1 von 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await db.close();
    },
  );
}
