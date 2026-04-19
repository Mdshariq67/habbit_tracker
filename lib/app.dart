import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_event.dart';
import 'package:habbit_tracker/data/habit_repository.dart';
import 'package:habbit_tracker/presentation/habits_list_screen.dart';

class HabbitTrackerApp extends StatelessWidget {
  const HabbitTrackerApp({
    super.key,
    required this.habitRepository,
  });

  final HabitRepository habitRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<HabitRepository>.value(
      value: habitRepository,
      child: BlocProvider(
        create: (_) =>
            HabitsBloc(habitRepository)..add(const HabitsStarted()),
        child: MaterialApp(
          title: 'Habit Tracker',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: const HabitsListScreen(),
        ),
      ),
    );
  }
}
