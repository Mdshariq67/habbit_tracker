import 'package:flutter/material.dart';
import 'package:habbit_tracker/app.dart';
import 'package:habbit_tracker/data/habit_repository.dart';
import 'package:habbit_tracker/data/models/habit.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _habitsBoxName = 'habits';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(HabitAdapter().typeId)) {
    Hive.registerAdapter(HabitAdapter());
  }
  final box = await Hive.openBox<Habit>(_habitsBoxName);
  final repository = HabitRepository(box);
  runApp(HabbitTrackerApp(habitRepository: repository));
}
