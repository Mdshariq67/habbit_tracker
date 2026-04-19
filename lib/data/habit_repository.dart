import 'package:habbit_tracker/data/models/habit.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local persistence for habits (Hive box).
class HabitRepository {
  HabitRepository(this._box);

  final Box<Habit> _box;

  List<Habit> getAll() {
    return _box.values.toList(growable: false);
  }

  Habit? getById(String id) => _box.get(id);

  Future<void> put(Habit habit) => _box.put(habit.id, habit);

  Future<void> update(Habit habit) => _box.put(habit.id, habit);

  Future<void> delete(String id) => _box.delete(id);
}
