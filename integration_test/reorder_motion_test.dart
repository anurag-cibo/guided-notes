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
import 'package:guided_notes/features/settings/data/settings_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: sortieren, Ziel wechseln und sanfte Navigation', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = GoalsRepository(db);
    final c = GoalsController(r);
    await r.saveGoal(
      motivation: 'Meine persönliche Richtung',
      title: 'Gesundheit',
      emoji: '🌿',
    );
    await r.saveGoal(
      motivation: 'Meine persönliche Richtung',
      title: 'Beruf & Lernen',
      emoji: '📚',
      color: GoalColor.lavender,
    );
    await r.saveMilestone(
      motivation: 'Mein nächster Schritt zum Ziel',
      goalId: 1,
      title: 'Regelmäßig bewegen',
      progress: 40,
    );
    await r.saveMilestone(
      motivation: 'Mein nächster Schritt zum Ziel',
      goalId: 1,
      title: 'Erholsam schlafen',
      progress: 65,
    );
    await r.saveMilestone(
      motivation: 'Mein nächster Schritt zum Ziel',
      goalId: 2,
      title: 'Etwas Neues lernen',
      progress: 20,
    );
    await SettingsRepository(db).saveAppearance(AppAppearance.light);
    await c.load();
    await tester.pumpWidget(GuideApp(controller: c));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('motion-ready');
    await tester.pump(const Duration(seconds: 2));
    Future<void> move(String source, String target, String shot) async {
      final from = find.byKey(ValueKey(source));
      final to = find.byKey(ValueKey(target));
      await tester.ensureVisible(from);
      await tester.pumpAndSettle();
      final start = tester.getCenter(from);
      final end = tester.getTopLeft(to) + const Offset(35, 12);
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 750));
      for (var i = 1; i <= 24; i++) {
        await gesture.moveTo(Offset.lerp(start, end, i / 24)!);
        await tester.pump(const Duration(milliseconds: 24));
      }
      await tester.pump(const Duration(milliseconds: 250));
      await binding.takeScreenshot('$shot-drag');
      await gesture.up();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('$shot-done');
      await tester.pump(const Duration(milliseconds: 650));
      expect(tester.takeException(), isNull);
    }

    await move('drag-goal-2', 'drag-goal-1', 'motion-goals');
    expect(c.snapshot.activeGoals.first.id, 2);
    await tester.tap(find.text('Gesundheit'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('drag-milestone-2')));
    await tester.pumpAndSettle();
    await move('drag-milestone-2', 'drag-milestone-1', 'motion-detail');
    expect(c.snapshot.forGoal(1).first.id, 2);
    Navigator.of(tester.element(find.byType(GoalDetail))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zwischenziele').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal-jump-2')));
    await tester.pump(const Duration(milliseconds: 100));
    await binding.takeScreenshot('motion-emoji-in');
    await tester.pump(const Duration(milliseconds: 350));
    await binding.takeScreenshot('motion-emoji-selected');
    await tester.pump(const Duration(milliseconds: 1400));
    await binding.takeScreenshot('motion-emoji-out');
    await move('drag-milestone-1', 'drag-milestone-3', 'motion-cross-goal');
    expect(c.snapshot.forGoal(2).map((m) => m.id), [1, 3]);
    await c.mutate(
      (r) => r.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Finanzen',
        emoji: '💰',
        color: GoalColor.amber,
      ),
    );
    await tester.pumpAndSettle();
    await move('drag-milestone-2', 'drop-goal-3', 'motion-empty-group');
    expect(c.snapshot.forGoal(3).single.id, 2);
    // Long list gives the navigation bar room to hide and reappear.
    await c.mutate((r) async {
      for (var i = 0; i < 10; i++) {
        await r.saveMilestone(
          motivation: 'Mein nächster Schritt zum Ziel',
          goalId: 2,
          title: 'Nächster Schritt ${i + 1}',
        );
      }
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal-jump-2')));
    await tester.pumpAndSettle();
    await tester.timedDrag(
      find.byType(CustomScrollView),
      const Offset(0, -300),
      const Duration(milliseconds: 700),
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('motion-bar-hidden');
    await tester.timedDrag(
      find.byType(CustomScrollView),
      const Offset(0, 80),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('motion-bar-shown');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await db.close();
  });
}
