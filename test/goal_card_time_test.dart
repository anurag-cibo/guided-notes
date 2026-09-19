import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/goal_time.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/goal_card.dart';

void main() {
  testWidgets(
    'card deadline ring shares detail timing and keeps clear labels',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final controller = GoalsController(GoalsRepository(db));
      final semantics = tester.ensureSemantics();
      final now = DateTime.now();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        for (final scale in [1.0, 2.0]) {
          for (final days in [103, 1, 0, -1, -103]) {
            final goal = Goal(
              id: 1,
              title: 'Gesundheit',
              startedOn: DateTime(now.year, now.month, now.day - 100),
              dueDate: DateTime(now.year, now.month, now.day + days),
            );
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: GoalCard(
                      controller: controller,
                      goal: goal,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            );
            final time = GoalTime(goal, now);
            expect(
              tester
                  .widget<CircularProgressIndicator>(
                    find.byType(CircularProgressIndicator),
                  )
                  .value,
              time.elapsed,
            );
            final label = days > 0
                ? '$days ${days == 1 ? 'Tag' : 'Tage'}'
                : time.label.replaceAll('\n', ' ');
            expect(find.text(label), findsOneWidget);
            // The tappable card merges the deadline into its full label.
            expect(
              find.bySemanticsLabel(RegExp('Zeit bis zur Frist')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
        for (final achieved in [false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: GoalCard(
                  controller: controller,
                  goal: Goal(id: 1, title: 'Gesundheit', achieved: achieved),
                  onTap: () {},
                ),
              ),
            ),
          );
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(
            find.text('Erreicht'),
            achieved ? findsOneWidget : findsNothing,
          );
        }
      } finally {
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
        controller.dispose();
        await db.close();
      }
    },
  );
}
