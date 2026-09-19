import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/features/goals/domain/models.dart';

void main() {
  test('progress is equal-weighted, rounded and absent without milestones', () {
    final empty = GoalSnapshot([], []);
    expect(empty.progressFor(1), isNull);
    final snapshot = GoalSnapshot([], [
      const Milestone(
        id: 1,
        goalId: 1,
        title: 'A',
        progress: 100,
        status: MilestoneStatus.achieved,
      ),
      const Milestone(
        id: 2,
        goalId: 1,
        title: 'B',
        progress: 25,
        status: MilestoneStatus.onTrack,
      ),
      const Milestone(id: 3, goalId: 1, title: 'C'),
      const Milestone(id: 4, goalId: 2, title: 'Other', progress: 100),
    ]);
    expect(snapshot.progressFor(1), 41.67);
  });
  test('status and progress stay consistent', () {
    expect(normalizeProgress(20, MilestoneStatus.achieved).progress, 100);
    expect(
      normalizeProgress(100, MilestoneStatus.onHold).status,
      MilestoneStatus.achieved,
    );
    expect(
      normalizeProgress(10, MilestoneStatus.notStarted).status,
      MilestoneStatus.onTrack,
    );
    expect(normalizeProgress(40, MilestoneStatus.onHold).progress, 40);
    expect(
      () => normalizeProgress(-1, MilestoneStatus.onTrack),
      throwsA(isA<RuleViolation>()),
    );
    expect(
      () => normalizeProgress(101, MilestoneStatus.onTrack),
      throwsA(isA<RuleViolation>()),
    );
    expect(() => requiredTitle('  '), throwsA(isA<RuleViolation>()));
  });
  test('deadlines compare calendar dates including DST and reached items', () {
    expect(deadlineLabel(null), 'Ohne Frist');
    expect(
      deadlineLabel(DateTime(2026, 3, 30), now: DateTime(2026, 3, 29, 23)),
      'Noch 1 Tag',
    );
    expect(
      deadlineLabel(
        DateTime(2026, 10, 25),
        now: DateTime(2026, 10, 25, 23, 59),
      ),
      'Heute fällig',
    );
    expect(
      deadlineLabel(DateTime(2026, 1, 1), now: DateTime(2026, 1, 3)),
      '2 Tage überfällig',
    );
    expect(deadlineLabel(DateTime(2020), achieved: true), 'Erreicht');
  });
}
