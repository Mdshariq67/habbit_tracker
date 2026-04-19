import 'package:habbit_tracker/data/models/habit.dart';

sealed class HabitsState {
  const HabitsState();
}

final class HabitsInitial extends HabitsState {
  const HabitsInitial();
}

final class HabitsLoading extends HabitsState {
  const HabitsLoading();
}

final class HabitsLoaded extends HabitsState {
  const HabitsLoaded(this.habits);

  final List<Habit> habits;
}

final class HabitsFailure extends HabitsState {
  const HabitsFailure(this.message);

  final String message;
}
