import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';

/// Requires the tester to save and then select the file in Android's picker.
/// Uses separate temporary databases, never the user's guide.sqlite.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: native backup file round trip', (tester) async {
    final directory = await Directory((await getTemporaryDirectory()).path)
        .createTemp('backup_test_');
    final source = AppDatabase(
      NativeDatabase(File('${directory.path}/source.sqlite')),
    );
    var target = AppDatabase(
      NativeDatabase(File('${directory.path}/target.sqlite')),
    );
    final repository = GoalsRepository(source);
    final controller = GoalsController(repository);
    try {
      await repository.saveGoal(
        title: 'Gesundheit',
        emoji: '🌿',
        motivation: 'Mehr Energie. Mehr Lebensqualität.',
      );
      final id = (await repository.load()).goals.single.id;
      await repository.saveMilestone(
        goalId: id,
        title: 'Regelmäßig bewegen',
        progress: 60,
        status: MilestoneStatus.onTrack,
      );
      await repository.saveMilestone(
        goalId: id,
        title: 'Bewusst essen',
        progress: 30,
        status: MilestoneStatus.offTrack,
      );
      await repository.saveGoal(
        title: 'Ein Buch schreiben',
        emoji: '📚',
        motivation: 'Meine Ideen festhalten.',
      );
      final archivedId = (await repository.load()).goals.last.id;
      await repository.setAchieved(archivedId, true);
      await repository.setArchived(archivedId, true);
      await controller.load();
      await tester.pumpWidget(GuideApp(controller: controller));
      await tester.pumpAndSettle();
      final backup = await repository.exportBackup();
      const channel = MethodChannel('de.anurag.guided_notes/backup');
      // The actual system document provider must acknowledge the write.
      expect(
        await channel.invokeMethod<bool>('save', {'contents': backup}),
        isTrue,
      );
      final imported = await channel.invokeMethod<String>('open');
      expect(imported, backup);
      await GoalsRepository(target).importBackup(imported!);
      await target.close();
      target = AppDatabase(
        NativeDatabase(File('${directory.path}/target.sqlite')),
      );
      expect(await GoalsRepository(target).exportBackup(), backup);
      await tester.pumpAndSettle();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await source.close();
      await target.close();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
