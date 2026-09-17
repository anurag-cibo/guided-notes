import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const verifyRestart = bool.fromEnvironment('VERIFY_RESTART');
  testWidgets(
    verifyRestart
        ? 'Android: Daten nach Prozessneustart'
        : 'Android: erster vollständiger Ablauf',
    (tester) async {
      final database = AppDatabase.local();
      final controller = GoalsController(GoalsRepository(database));
      await controller.load();
      expect(controller.error, isNull);
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      if (verifyRestart) {
        final goal = controller.snapshot.goals.singleWhere(
          (g) => g.title == 'Android-Testziel',
        );
        expect(goal.motivation, 'Neustart und Offline-Speicherung prüfen');
        expect(
          controller.snapshot.forGoal(goal.id).single.status,
          MilestoneStatus.achieved,
        );
        expect(controller.snapshot.progressFor(goal.id), 100);
        await tester.tap(find.text('Android-Testziel'));
        await tester.pumpAndSettle();
        expect(find.text('100 %'), findsOneWidget);
        // Remove only this test's synthetic data, after proving persistence.
        await controller.repository.setArchived(goal.id, true);
        await controller.repository.deleteGoal(goal.id);
      } else {
        expect(
          controller.snapshot.goals.where((g) => g.title == 'Android-Testziel'),
          isEmpty,
        );
        await tester.tap(find.text('Ziel hinzufügen'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('goal-title')),
          'Android-Testziel',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'Neustart und Offline-Speicherung prüfen',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Speichern'));
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Android-Testziel'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Zwischenziel hinzufügen'));
        await tester.tap(find.text('Zwischenziel hinzufügen'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'App auf Android starten',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<MilestoneStatus>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Erreicht').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Speichern'));
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        expect(find.text('100 %'), findsOneWidget);
        await tester.tap(find.text('App auf Android starten'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Erreicht · 100 %'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Zieldetails'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await database.close();
    },
  );
}
