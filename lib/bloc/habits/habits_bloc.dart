import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_event.dart';
import 'package:habbit_tracker/bloc/habits/habits_state.dart';
import 'package:habbit_tracker/data/habit_repository.dart';
import 'package:habbit_tracker/data/models/habit.dart';

class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  HabitsBloc(this._repository) : super(const HabitsInitial()) {
    on<HabitsStarted>(_onStarted);
    on<HabitsHabitAdded>(_onHabitAdded);
    on<HabitsHabitDeleted>(_onHabitDeleted);
    on<HabitsHabitToggled>(_onHabitToggled);
    on<HabitsHabitUpdated>(_onHabitUpdated);
  }

  final HabitRepository _repository;

  Future<void> _onStarted(
    HabitsStarted event,
    Emitter<HabitsState> emit,
  ) async {
    emit(const HabitsLoading());
    try {
      final habits = _sorted(_repository.getAll());
      emit(HabitsLoaded(habits));
    } catch (e) {
      emit(HabitsFailure(e.toString()));
    }
  }

  Future<void> _onHabitAdded(
    HabitsHabitAdded event,
    Emitter<HabitsState> emit,
  ) async {
    final title = event.title.trim();
    if (title.isEmpty) return;

    final previous = _currentHabits();

    final habit = Habit(
      id: _newHabitId(),
      title: title,
      description: event.description.trim(),
      createdAt: DateTime.now(),
    );

    emit(HabitsLoaded(_sorted([...previous, habit])));
    unawaited(_repository.put(habit));
  }

  Future<void> _onHabitDeleted(
    HabitsHabitDeleted event,
    Emitter<HabitsState> emit,
  ) async {
    final previous = _currentHabits();
    final updated = previous.where((h) => h.id != event.habitId).toList();

    emit(HabitsLoaded(_sorted(updated)));
    unawaited(_repository.delete(event.habitId));
  }

  Future<void> _onHabitToggled(
    HabitsHabitToggled event,
    Emitter<HabitsState> emit,
  ) async {
    final previous = _currentHabits();
    final updated = previous.map((h) {
      if (h.id == event.habitId) return h.toggleToday();
      return h;
    }).toList();

    emit(HabitsLoaded(_sorted(updated)));

    final toggled = updated.firstWhere((h) => h.id == event.habitId);
    unawaited(_repository.update(toggled));
  }

  Future<void> _onHabitUpdated(
    HabitsHabitUpdated event,
    Emitter<HabitsState> emit,
  ) async {
    final title = event.title.trim();
    if (title.isEmpty) return;

    final previous = _currentHabits();
    final updated = previous.map((h) {
      if (h.id == event.habitId) {
        return h.copyWith(title: title, description: event.description.trim());
      }
      return h;
    }).toList();

    emit(HabitsLoaded(_sorted(updated)));

    final habit = updated.firstWhere((h) => h.id == event.habitId);
    unawaited(_repository.update(habit));
  }

  List<Habit> _currentHabits() {
    return state is HabitsLoaded
        ? List<Habit>.from((state as HabitsLoaded).habits)
        : <Habit>[];
  }

  List<Habit> _sorted(List<Habit> habits) {
    final copy = List<Habit>.from(habits);
    copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return copy;
  }

  String _newHabitId() =>
      'habit-${DateTime.now().microsecondsSinceEpoch}';
}
