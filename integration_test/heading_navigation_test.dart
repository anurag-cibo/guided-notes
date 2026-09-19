import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/goal_detail.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android: Überschriften wechseln zwischen Details und Zielgruppe',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final r = GoalsRepository(db);
      final c = GoalsController(r);
      try {
        await r.saveGoal(title: 'Gesundheit', emoji: '🌿');
        for (var i = 0; i < 20; i++) {
          await r.saveMilestone(
            motivation: 'Mein nächster Schritt zum Ziel',
            goalId: 1,
            title: 'Schritt ${i + 1}',
          );
        }
        await r.saveGoal(
          title: 'Beruf & Lernen',
          emoji: '📚',
          color: GoalColor.lavender,
        );
        await r.saveMilestone(
          motivation: 'Mein nächster Schritt zum Ziel',
          goalId: 2,
          title: 'Etwas Neues lernen',
          progress: 35,
        );
        await c.load();
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beruf & Lernen'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Zwischenziele'));
        await tester.tap(find.text('Zwischenziele'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        expect(find.text('📚 Beruf & Lernen').hitTestable(), findsOneWidget);
        await binding.takeScreenshot('navigation-focused-group');
        await tester.tap(find.text('📚 Beruf & Lernen'));
        await tester.pumpAndSettle();
        expect(tester.widget<GoalDetail>(find.byType(GoalDetail)).goalId, 2);
        await binding.takeScreenshot('navigation-goal-detail');
        await tester.tap(find.text('Zwischenziele'));
        await tester.pumpAndSettle();
        expect(find.byType(GoalDetail), findsNothing);
        await tester.tap(find.byKey(const ValueKey('goal-jump-2')));
        await tester.pump(const Duration(milliseconds: 250));
        await binding.takeScreenshot('navigation-after-flash');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await db.close();
      }
    },
  );
}
