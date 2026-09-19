import 'dart:convert';
import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Profile: scroll, slider and Todo updates', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = GoalsRepository(db);
    final controller = GoalsController(repo);
    try {
      for (var goal = 1; goal <= 5; goal++) {
        await repo.saveGoal(title: 'Ziel $goal', motivation: 'Profilprüfung');
        for (var i = 0; i < 20; i++) {
          await repo.saveMilestone(goalId: goal, title: 'Schritt $goal.$i');
        }
      }
      for (var i = 0; i < 12; i++) {
        await repo.todos.save(
          title: 'Aufgabe $i',
          frequency: TodoFrequency.daily,
          target: 1,
          milestoneId: 1,
          progressIncrement: .5,
        );
      }
      await controller.load();
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();

      Future<void> measure(String name, Future<void> Function() action) async {
        final frames = <FrameTiming>[];
        void collect(List<FrameTiming> values) => frames.addAll(values);
        SchedulerBinding.instance.addTimingsCallback(collect);
        await action();
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        SchedulerBinding.instance.removeTimingsCallback(collect);
        Map<String, Object> stats(List<double> values) {
          values.sort();
          if (values.isEmpty) return {'frames': 0};
          double percentile(double p) =>
              values[((values.length - 1) * p).round()];
          return {
            'frames': values.length,
            'p50_ms': percentile(.5),
            'p95_ms': percentile(.95),
            'max_ms': values.last,
            'over_16_67_ms': values.where((v) => v > 16.67).length,
          };
        }

        // Measured on an emulator; these are diagnostics, not device FPS claims.
        debugPrint(
          'PERF ${jsonEncode({'scenario': name, 'build': stats(frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()), 'raster': stats(frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList())})}',
        );
      }

      await tester.tap(find.text('Zwischenziele').last);
      await tester.pumpAndSettle();
      Future<void> scroll() async {
        for (var i = 0; i < 8; i++) {
          await tester.fling(
            find.byType(CustomScrollView).first,
            Offset(0, i.isEven ? -500 : 500),
            1400,
          );
          await tester.pumpAndSettle();
        }
      }

      await scroll();
      await measure('milestones_scroll_100', scroll);
      await tester.tap(find.byKey(const ValueKey('goal-jump-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schritt 1.0'));
      await tester.pumpAndSettle();
      final slider = find.byKey(const ValueKey('metric-slider'));
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      Future<void> slide() async {
        final rect = tester.getRect(slider);
        final gesture = await tester.startGesture(
          Offset(rect.left + 16, rect.center.dy),
        );
        for (var i = 0; i < 80; i++) {
          final progress = i < 40 ? i / 39 : (79 - i) / 39;
          await gesture.moveTo(
            Offset(
              rect.left + 16 + (rect.width - 32) * progress,
              rect.center.dy,
            ),
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await slide();
      await measure('slider_12_linked_todos', slide);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos').last);
      await tester.pumpAndSettle();
      await measure('todo_toggle_12_rows', () async {
        for (var i = 0; i < 12; i++) {
          await tester.tap(find.byType(Checkbox).first);
          await tester.pumpAndSettle();
        }
      });
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await db.close();
    }
  });
}
