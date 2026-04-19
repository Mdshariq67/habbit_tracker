import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_event.dart';
import 'package:habbit_tracker/bloc/habits/habits_state.dart';
import 'package:habbit_tracker/data/models/habit.dart';
import 'package:habbit_tracker/presentation/add_habit_dialog.dart';
import 'package:habbit_tracker/presentation/habit_detail_screen.dart';

/// Home screen: lists habits from [HabitsBloc].
class HabitsListScreen extends StatelessWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        centerTitle: true,
      ),
      body: BlocConsumer<HabitsBloc, HabitsState>(
        listener: (context, state) {
          if (state is HabitsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            HabitsInitial() => const SizedBox.shrink(),
            HabitsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            HabitsFailure() => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _reload(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            HabitsLoaded(:final habits) => habits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.track_changes,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No habits yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add your first one.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _HabitsList(habits: habits),
          };
        },
      ),
      floatingActionButton: BlocBuilder<HabitsBloc, HabitsState>(
        buildWhen: (previous, current) =>
            current is HabitsLoaded || previous is HabitsLoaded,
        builder: (context, state) {
          if (state is! HabitsLoaded) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _showAddDialog(context),
            tooltip: 'Add habit',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final bloc = context.read<HabitsBloc>();
    final result = await showAddHabitDialog(context);
    if (result == null) return;
    bloc.add(HabitsHabitAdded(
      title: result.title,
      description: result.description,
    ));
  }

  static void _reload(BuildContext context) {
    context.read<HabitsBloc>().add(const HabitsStarted());
  }
}

class _HabitsList extends StatelessWidget {
  const _HabitsList({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: habits.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final h = habits[index];
        return _HabitTile(habit: h);
      },
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: IconButton(
        key: Key('toggle-${habit.id}'),
        icon: Icon(
          habit.isCompletedToday ? Icons.check_circle : Icons.circle_outlined,
          color: habit.isCompletedToday
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          context.read<HabitsBloc>().add(HabitsHabitToggled(habit.id));
        },
        tooltip: habit.isCompletedToday ? 'Mark incomplete' : 'Mark complete',
      ),
      title: Text(
        habit.title,
        style: TextStyle(
          decoration: habit.isCompletedToday ? TextDecoration.lineThrough : null,
          color: habit.isCompletedToday
              ? colorScheme.onSurfaceVariant
              : colorScheme.onSurface,
        ),
      ),
      subtitle: habit.currentStreak > 0
          ? Text('${habit.currentStreak}-day streak')
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<HabitsBloc>(),
              child: HabitDetailScreen(habitId: habit.id),
            ),
          ),
        );
      },
    );
  }
}
