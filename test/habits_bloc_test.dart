import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habbit_tracker/bloc/habits/habits_bloc.dart';
import 'package:habbit_tracker/bloc/habits/habits_event.dart';
import 'package:habbit_tracker/bloc/habits/habits_state.dart';
import 'package:habbit_tracker/data/habit_repository.dart';
import 'package:habbit_tracker/data/models/habit.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  const boxName = 'bloc_test_box';

  late Directory hiveDir;
  late Box<Habit> box;
  late HabitRepository repository;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('bloc_test_hive_');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(HabitAdapter().typeId)) {
      Hive.registerAdapter(HabitAdapter());
    }
  });

  tearDownAll(() async {
    try {
      await Hive.close();
    } catch (_) {}
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (Hive.isBoxOpen(boxName)) {
      box = Hive.box<Habit>(boxName);
    } else {
      box = await Hive.openBox<Habit>(boxName);
    }
    await box.clear();
    repository = HabitRepository(box);
  });

  group('HabitsBloc', () {
    blocTest<HabitsBloc, HabitsState>(
      'emits [HabitsLoading, HabitsLoaded] on HabitsStarted with empty repo',
      build: () => HabitsBloc(repository),
      act: (bloc) => bloc.add(const HabitsStarted()),
      expect: () => [
        isA<HabitsLoading>(),
        isA<HabitsLoaded>().having((s) => s.habits, 'habits', isEmpty),
      ],
    );

    blocTest<HabitsBloc, HabitsState>(
      'emits loaded habits sorted alphabetically',
      setUp: () async {
        await repository.put(Habit(id: '2', title: 'Zzz', createdAt: DateTime(2026)));
        await repository.put(Habit(id: '1', title: 'Aaa', createdAt: DateTime(2026)));
      },
      build: () => HabitsBloc(repository),
      act: (bloc) => bloc.add(const HabitsStarted()),
      expect: () => [
        isA<HabitsLoading>(),
        isA<HabitsLoaded>().having(
          (s) => s.habits.map((h) => h.title).toList(),
          'sorted titles',
          ['Aaa', 'Zzz'],
        ),
      ],
    );

    blocTest<HabitsBloc, HabitsState>(
      'HabitsHabitAdded creates habit and emits updated list',
      build: () => HabitsBloc(repository),
      seed: () => const HabitsLoaded([]),
      act: (bloc) => bloc.add(const HabitsHabitAdded(title: 'Meditate')),
      expect: () => [
        isA<HabitsLoaded>().having(
          (s) => s.habits.length,
          'habits count',
          1,
        ),
      ],
      verify: (_) {
        expect(repository.getAll().length, 1);
        expect(repository.getAll().first.title, 'Meditate');
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'HabitsHabitAdded ignores blank title',
      build: () => HabitsBloc(repository),
      seed: () => const HabitsLoaded([]),
      act: (bloc) => bloc.add(const HabitsHabitAdded(title: '   ')),
      expect: () => <HabitsState>[],
    );

    blocTest<HabitsBloc, HabitsState>(
      'HabitsHabitAdded trims title whitespace',
      build: () => HabitsBloc(repository),
      seed: () => const HabitsLoaded([]),
      act: (bloc) => bloc.add(const HabitsHabitAdded(title: '  Read  ')),
      expect: () => [
        isA<HabitsLoaded>().having(
          (s) => s.habits.first.title,
          'trimmed title',
          'Read',
        ),
      ],
    );

    blocTest<HabitsBloc, HabitsState>(
      'HabitsHabitDeleted removes habit from state and repo',
      setUp: () async {
        await repository.put(Habit(id: 'd1', title: 'Walk', createdAt: DateTime(2026)));
      },
      build: () => HabitsBloc(repository),
      seed: () => [
        Habit(id: 'd1', title: 'Walk', createdAt: DateTime(2026)),
      ].let((h) => HabitsLoaded(h)),
      act: (bloc) => bloc.add(const HabitsHabitDeleted('d1')),
      expect: () => [
        isA<HabitsLoaded>().having((s) => s.habits, 'habits', isEmpty),
      ],
      verify: (_) {
        expect(repository.getAll(), isEmpty);
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'HabitsHabitToggled toggles completion for today',
      setUp: () async {
        await repository.put(
          Habit(id: 't1', title: 'Yoga', createdAt: DateTime(2026)),
        );
      },
      build: () => HabitsBloc(repository),
      seed: () => HabitsLoaded([
        Habit(id: 't1', title: 'Yoga', createdAt: DateTime(2026)),
      ]),
      act: (bloc) => bloc.add(const HabitsHabitToggled('t1')),
      expect: () => [
        isA<HabitsLoaded>().having(
          (s) => s.habits.first.isCompletedToday,
          'completed today',
          true,
        ),
      ],
    );

    blocTest<HabitsBloc, HabitsState>(
      'HabitsHabitUpdated changes title and description',
      setUp: () async {
        await repository.put(
          Habit(id: 'u1', title: 'Old', createdAt: DateTime(2026)),
        );
      },
      build: () => HabitsBloc(repository),
      seed: () => HabitsLoaded([
        Habit(id: 'u1', title: 'Old', createdAt: DateTime(2026)),
      ]),
      act: (bloc) => bloc.add(const HabitsHabitUpdated(
        habitId: 'u1',
        title: 'New',
        description: 'Daily morning',
      )),
      expect: () => [
        isA<HabitsLoaded>()
            .having((s) => s.habits.first.title, 'title', 'New')
            .having(
              (s) => s.habits.first.description,
              'description',
              'Daily morning',
            ),
      ],
    );

    blocTest<HabitsBloc, HabitsState>(
      'HabitsHabitUpdated ignores blank title',
      build: () => HabitsBloc(repository),
      seed: () => HabitsLoaded([
        Habit(id: 'u2', title: 'Keep', createdAt: DateTime(2026)),
      ]),
      act: (bloc) => bloc.add(const HabitsHabitUpdated(
        habitId: 'u2',
        title: '   ',
      )),
      expect: () => <HabitsState>[],
    );
  });
}

extension _Let<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
