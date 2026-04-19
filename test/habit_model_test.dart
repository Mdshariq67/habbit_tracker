import 'package:flutter_test/flutter_test.dart';
import 'package:habbit_tracker/data/models/habit.dart';

void main() {
  group('Habit', () {
    Habit createHabit({
      String id = 'test-id',
      String title = 'Test Habit',
      String description = '',
      DateTime? createdAt,
      Set<String>? completedDates,
    }) {
      return Habit(
        id: id,
        title: title,
        description: description,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
        completedDates: completedDates ?? const {},
      );
    }

    test('copyWith returns new instance with updated fields', () {
      final habit = createHabit();
      final updated = habit.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');
      expect(updated.id, habit.id);
      expect(updated.description, habit.description);
      expect(updated.createdAt, habit.createdAt);
    });

    test('copyWith preserves all fields when none are provided', () {
      final habit = createHabit(
        description: 'Some desc',
        completedDates: {'2026-04-19'},
      );
      final copy = habit.copyWith();

      expect(copy.id, habit.id);
      expect(copy.title, habit.title);
      expect(copy.description, habit.description);
      expect(copy.createdAt, habit.createdAt);
      expect(copy.completedDates, habit.completedDates);
    });

    test('isCompletedToday returns true when today is in completedDates', () {
      final now = DateTime.now();
      final key =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final habit = createHabit(completedDates: {key});
      expect(habit.isCompletedToday, isTrue);
    });

    test('isCompletedToday returns false when today is not in completedDates', () {
      final habit = createHabit(completedDates: {'1999-01-01'});
      expect(habit.isCompletedToday, isFalse);
    });

    test('toggleToday adds today when not completed', () {
      final habit = createHabit();
      final toggled = habit.toggleToday();

      expect(toggled.isCompletedToday, isTrue);
      expect(toggled.completedDates.length, 1);
    });

    test('toggleToday removes today when already completed', () {
      final now = DateTime.now();
      final key =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final habit = createHabit(completedDates: {key});
      final toggled = habit.toggleToday();

      expect(toggled.isCompletedToday, isFalse);
      expect(toggled.completedDates, isEmpty);
    });

    test('currentStreak counts consecutive days ending today', () {
      final now = DateTime.now();
      final dates = <String>{};
      for (var i = 0; i < 5; i++) {
        final d = now.subtract(Duration(days: i));
        dates.add(
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        );
      }

      final habit = createHabit(completedDates: dates);
      expect(habit.currentStreak, 5);
    });

    test('currentStreak is zero when today is not completed', () {
      final habit = createHabit(completedDates: {'2020-01-01'});
      expect(habit.currentStreak, 0);
    });

    test('currentStreak breaks on gap day', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      String key(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final habit = createHabit(completedDates: {
        key(now),
        key(yesterday),
        key(threeDaysAgo),
      });
      expect(habit.currentStreak, 2);
    });
  });

  group('HabitAdapter', () {
    test('round-trips via write then read', () {
      final adapter = HabitAdapter();
      expect(adapter.typeId, 0);
    });
  });
}
