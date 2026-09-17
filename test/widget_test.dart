import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/milestones_screen.dart';
import 'package:guided_notes/features/goals/presentation/backup_screen.dart';
import 'package:guided_notes/features/goals/presentation/goal_detail.dart';

void main() {
  late AppDatabase database;
  late GoalsController controller;
  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    controller = GoalsController(GoalsRepository(database));
    await controller.load();
  });
  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  testWidgets(
    'details preserve deadline, motivation edits and archive delete confirmation',
    (tester) async {
      await controller.repository.saveGoal(
        title: 'Lesen',
        motivation: 'Neugier',
        dueDate: DateTime(2020, 1, 1),
      );
      final id = (await controller.repository.load()).goals.single.id;
      await controller.repository.saveMilestone(
        goalId: id,
        title: 'Ein Buch',
        progress: 50,
        status: MilestoneStatus.onTrack,
      );
      await controller.load();
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lesen'));
      await tester.pumpAndSettle();
      expect(find.text('Neugier'), findsOneWidget);
      expect(find.textContaining('überfällig'), findsOneWidget);
      await tester.tap(find.byTooltip('Ziel bearbeiten'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'Neue Motivation',
      );
      await tester.ensureVisible(find.text('Speichern'));
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Neue Motivation'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Ziel erreicht'), 250);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(controller.snapshot.goal(id)!.achieved, isTrue);
      expect(controller.snapshot.goal(id)!.archived, isFalse);
      await tester.scrollUntilVisible(find.text('Ziel archivieren'), 250);
      await tester.tap(find.text('Ziel archivieren'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.activeGoals, isEmpty);
      await tester.tap(find.text('Zwischenziele').last);
      await tester.pumpAndSettle();
      expect(find.text('Ein Buch'), findsNothing);
      await tester.tap(find.text('Ziele').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Archiv'));
      await tester.tap(find.text('Archiv'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lesen'));
      await tester.pumpAndSettle();
      final detailContext = tester.element(find.byType(GoalDetail));
      final formattedDate = MaterialLocalizations.of(detailContext)
          .formatMediumDate(DateTime(2020, 1, 1));
      expect(find.text('Frist: $formattedDate'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Ziel endgültig löschen'), 250);
      await tester.tap(find.text('Ziel endgültig löschen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('alle 1 Zwischenziele'), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.milestones, hasLength(1));
      await tester.tap(find.text('Ziel endgültig löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Endgültig löschen'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.goals, isEmpty);
      expect(controller.snapshot.milestones, isEmpty);
    },
  );

  testWidgets(
    'empty details and backup import preview, cancellation and export',
    (tester) async {
      await controller.repository.saveGoal(title: 'Ohne Schritte');
      await controller.load();
      final backup = await controller.repository.exportBackup();
      final id = controller.snapshot.goals.single.id;
      await tester.pumpWidget(
        MaterialApp(
          home: GoalDetail(controller: controller, goalId: id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Zwischenziele'), findsOneWidget);
      expect(find.text('Frist: Ohne Frist'), findsOneWidget);
      await controller.repository.setArchived(id, true);
      await controller.repository.deleteGoal(id);
      await controller.load();
      const channel = MethodChannel('de.anurag.guided_notes/backup');
      String? exported;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'open') return backup;
        exported = (call.arguments as Map)['contents'] as String;
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: BackupScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sicherung auswählen'));
      await tester.tap(find.text('Sicherung auswählen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('1 Ziele (davon 0 archiviert)'),
        findsOneWidget,
      );
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.goals, isEmpty);
      await tester.tap(find.text('Sicherung auswählen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilledButton, 'Wiederherstellen'));
      await tester.pumpAndSettle();
      expect(controller.snapshot.goals.single.title, 'Ohne Schritte');
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Sicherung auswählen'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Sicherung exportieren'));
      await tester.tap(find.text('Sicherung exportieren'));
      await tester.pumpAndSettle();
      expect(exported, backup);
    },
  );

  testWidgets('empty state to reached milestone, direct navigation and back', (
    tester,
  ) async {
    await tester.pumpWidget(GuideApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Ziele'), findsOneWidget);
    await tester.tap(find.text('Ziel hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Bitte einen Titel eingeben.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Balkon begrünen');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balkon begrünen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zwischenziel hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Pflanzen auswählen',
    );
    await tester.ensureVisible(find.text('Speichern'));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pflanzen auswählen'));
    await tester.pumpAndSettle();
    expect(find.byType(MilestonesScreen), findsOneWidget);
    await tester.tap(find.text('Pflanzen auswählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<MilestoneStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erreicht').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Speichern'));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Erreicht · 100 %'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('100 %'), findsOneWidget);
    expect(controller.snapshot.goals.single.achieved, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zwischenziele').last);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Ziel hinzufügen'), findsOneWidget);
  });

  testWidgets(
    'five goals hide plus, archive always available, large text fits',
    (tester) async {
      for (var i = 0; i < 5; i++) {
        await controller.repository.saveGoal(
          title: 'Ein ausführlicher Zielname Nummer $i',
        );
      }
      await controller.load();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Ziel hinzufügen'), findsNothing);
      await tester.scrollUntilVisible(find.text('Archiv'), 400);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Archiv'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archiv'));
      await tester.pumpAndSettle();
      expect(find.text('Keine archivierten Ziele'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('direct target near end of long list and cluster switch', (
    tester,
  ) async {
    await controller.repository.saveGoal(title: 'Erstes Ziel');
    await controller.repository.saveGoal(title: 'Zweites Ziel');
    final goals = (await controller.repository.load()).goals;
    for (var i = 0; i < 80; i++) {
      await controller.repository.saveMilestone(
        goalId: goals.first.id,
        title: 'Schritt $i',
      );
    }
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: MilestonesScreen(
          controller: controller,
          focusGoalId: goals.first.id,
          focusMilestoneId: controller.snapshot.milestones.last.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Schritt 79').hitTestable(), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('◎ Zweites Ziel').last);
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Zwischenziele').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
