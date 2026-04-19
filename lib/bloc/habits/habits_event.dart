sealed class HabitsEvent {
  const HabitsEvent();
}

/// Load habits from local storage (Hive).
final class HabitsStarted extends HabitsEvent {
  const HabitsStarted();
}

/// Persist a new habit and refresh the list.
final class HabitsHabitAdded extends HabitsEvent {
  const HabitsHabitAdded({required this.title, this.description = ''});

  final String title;
  final String description;
}

/// Remove a habit from storage.
final class HabitsHabitDeleted extends HabitsEvent {
  const HabitsHabitDeleted(this.habitId);

  final String habitId;
}

/// Toggle today's completion status for a habit.
final class HabitsHabitToggled extends HabitsEvent {
  const HabitsHabitToggled(this.habitId);

  final String habitId;
}

/// Update title/description of an existing habit.
final class HabitsHabitUpdated extends HabitsEvent {
  const HabitsHabitUpdated({
    required this.habitId,
    required this.title,
    this.description = '',
  });

  final String habitId;
  final String title;
  final String description;
}
