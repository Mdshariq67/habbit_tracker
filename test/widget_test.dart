import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habbit_tracker/bloc/habits/habits_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_event.dart';
import 'package:habbit_tracker/data/habit_repository.dart';
import 'package:habbit_tracker/data/models/habit.dart';
import 'package:habbit_tracker/presentation/habits_list_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// In-memory repository that avoids Hive I/O in widget tests.
class FakeHabitRepository implements HabitRepository {
  final Map<String, Habit> _store = {};

  @override
  List<Habit> getAll() => _store.values.toList();

  @override
  Habit? getById(String id) => _store[id];

  @override
  Future<void> put(Habit habit) async => _store[habit.id] = habit;

  @override
  Future<void> update(Habit habit) async => _store[habit.id] = habit;

  @override
  Future<void> delete(String id) async => _store.remove(id);

  void seed(List<Habit> habits) {
    for (final h in habits) {
      _store[h.id] = h;
    }
  }

  void clear() => _store.clear();
}

void main() {
  late FakeHabitRepository repository;

  setUp(() {
    repository = FakeHabitRepository();
  });

  Widget buildApp() {
    return MaterialApp(
      home: RepositoryProvider<HabitRepository>.value(
        value: repository,
        child: BlocProvider(
          create: (_) => HabitsBloc(repository)..add(const HabitsStarted()),
          child: const HabitsListScreen(),
        ),
      ),
    );
  }

  testWidgets('shows empty state message after load', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('No habits yet'), findsOneWidget);
    expect(find.text('Tap + to add your first one.'), findsOneWidget);
  });

  testWidgets('add habit via dialog appears in list', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('New habit'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('add-habit-title-field')),
      'Drink water',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-habit-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Drink water'), findsOneWidget);
    expect(repository.getAll(), isNotEmpty);
    expect(repository.getAll().single.title, 'Drink water');
  });

  testWidgets('dialog shows error when submitting empty title', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('add-habit-submit')));
    await tester.pump();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('cancel dialog does not add a habit', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.getAll(), isEmpty);
  });

  testWidgets('tap habit navigates to detail screen', (WidgetTester tester) async {
    repository.seed([
      Habit(id: 'seed-1', title: 'Walk', createdAt: DateTime(2026, 4, 1)),
    ]);

    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.text('Walk'));
    await tester.pumpAndSettle();

    expect(find.text('Walk'), findsWidgets);
    expect(find.text('seed-1'), findsOneWidget);
  });

  testWidgets('toggle completion icon updates on tap', (WidgetTester tester) async {
    repository.seed([
      Habit(id: 'toggle-1', title: 'Meditate', createdAt: DateTime(2026, 4, 1)),
    ]);

    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-toggle-1')));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('habits display in alphabetical order', (WidgetTester tester) async {
    repository.seed([
      Habit(id: 'z', title: 'Zzz', createdAt: DateTime(2026)),
      Habit(id: 'a', title: 'Aaa', createdAt: DateTime(2026)),
      Habit(id: 'm', title: 'Mmm', createdAt: DateTime(2026)),
    ]);

    await tester.pumpWidget(buildApp());
    await tester.pump();

    final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(listTiles.length, 3);

    final titles = listTiles
        .map((tile) => ((tile.title as Text?)?.data ?? ''))
        .toList();
    expect(titles, ['Aaa', 'Mmm', 'Zzz']);
  });
}
