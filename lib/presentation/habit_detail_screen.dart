import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_event.dart';
import 'package:habbit_tracker/bloc/habits/habits_state.dart';
import 'package:habbit_tracker/data/models/habit.dart';
import 'package:habbit_tracker/presentation/add_habit_dialog.dart';

/// Detail screen for a single habit with toggle, edit, and delete actions.
class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitsBloc, HabitsState>(
      builder: (context, state) {
        if (state is! HabitsLoaded) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habit')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final habit = state.habits.where((h) => h.id == habitId).firstOrNull;
        if (habit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }

        return _DetailView(habit: habit);
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit'),
        actions: [
          IconButton(
            key: const Key('edit-habit-btn'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _editHabit(context),
          ),
          IconButton(
            key: const Key('delete-habit-btn'),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            habit.title,
            style: theme.textTheme.headlineSmall,
          ),
          if (habit.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              habit.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _StatusCard(habit: habit),
          const SizedBox(height: 16),
          _InfoCard(habit: habit),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('toggle-today-fab'),
        onPressed: () {
          context.read<HabitsBloc>().add(HabitsHabitToggled(habit.id));
        },
        icon: Icon(
          habit.isCompletedToday ? Icons.undo : Icons.check,
        ),
        label: Text(habit.isCompletedToday ? 'Undo today' : 'Complete today'),
      ),
    );
  }

  Future<void> _editHabit(BuildContext context) async {
    final bloc = context.read<HabitsBloc>();
    final result = await showAddHabitDialog(
      context,
      initialTitle: habit.title,
      initialDescription: habit.description,
    );
    if (result == null) return;
    bloc.add(HabitsHabitUpdated(
      habitId: habit.id,
      title: result.title,
      description: result.description,
    ));
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Are you sure you want to delete "${habit.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<HabitsBloc>().add(HabitsHabitDeleted(habit.id));
    Navigator.of(context).pop();
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _StatColumn(
                label: 'Today',
                value: habit.isCompletedToday ? 'Done' : 'Pending',
                icon: habit.isCompletedToday
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: habit.isCompletedToday
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outlineVariant,
            ),
            Expanded(
              child: _StatColumn(
                label: 'Streak',
                value: '${habit.currentStreak} days',
                icon: Icons.local_fire_department,
                color: habit.currentStreak > 0
                    ? colorScheme.tertiary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outlineVariant,
            ),
            Expanded(
              child: _StatColumn(
                label: 'Total',
                value: '${habit.completedDates.length}',
                icon: Icons.calendar_month,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Created',
              value: _formatDate(habit.createdAt),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'ID',
              value: habit.id,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
