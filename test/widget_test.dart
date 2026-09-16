import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/milestones_screen.dart';

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
    expect(find.text('Zwischenzielfortschritt: 100 %'), findsOneWidget);
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
