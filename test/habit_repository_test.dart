import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habbit_tracker/data/habit_repository.dart';
import 'package:habbit_tracker/data/models/habit.dart';
import 'package:hive/hive.dart';

void main() {
  const boxName = 'repo_test';

  late Directory hiveDir;
  late Box<Habit> box;
  late HabitRepository repo;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('repo_test_hive_');
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
    repo = HabitRepository(box);
  });

  Habit makeHabit({String id = 'h1', String title = 'Run'}) {
    return Habit(
      id: id,
      title: title,
      createdAt: DateTime(2026, 4, 19),
    );
  }

  group('HabitRepository', () {
    test('getAll returns empty list initially', () {
      expect(repo.getAll(), isEmpty);
    });

    test('put stores a habit and getAll retrieves it', () async {
      final habit = makeHabit();
      await repo.put(habit);

      final all = repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'h1');
      expect(all.first.title, 'Run');
    });

    test('getById returns stored habit', () async {
      final habit = makeHabit();
      await repo.put(habit);

      final found = repo.getById('h1');
      expect(found, isNotNull);
      expect(found!.title, 'Run');
    });

    test('getById returns null for unknown id', () {
      expect(repo.getById('nonexistent'), isNull);
    });

    test('update replaces an existing habit', () async {
      final habit = makeHabit();
      await repo.put(habit);

      final updated = habit.copyWith(title: 'Swim');
      await repo.update(updated);

      final all = repo.getAll();
      expect(all.length, 1);
      expect(all.first.title, 'Swim');
    });

    test('delete removes a habit', () async {
      await repo.put(makeHabit());
      expect(repo.getAll(), isNotEmpty);

      await repo.delete('h1');
      expect(repo.getAll(), isEmpty);
    });

    test('delete is a no-op for unknown id', () async {
      await repo.put(makeHabit());
      await repo.delete('unknown');

      expect(repo.getAll().length, 1);
    });

    test('put multiple habits and retrieve all', () async {
      await repo.put(makeHabit(id: 'a', title: 'Alpha'));
      await repo.put(makeHabit(id: 'b', title: 'Beta'));
      await repo.put(makeHabit(id: 'c', title: 'Charlie'));

      expect(repo.getAll().length, 3);
    });

    test('Hive adapter round-trips all Habit fields', () async {
      final habit = Habit(
        id: 'round-trip',
        title: 'Meditate',
        description: 'Morning session',
        createdAt: DateTime(2026, 3, 15, 10, 30),
        completedDates: {'2026-03-14', '2026-03-15'},
      );
      await repo.put(habit);

      final loaded = repo.getById('round-trip')!;
      expect(loaded.id, habit.id);
      expect(loaded.title, habit.title);
      expect(loaded.description, habit.description);
      expect(
        loaded.createdAt.millisecondsSinceEpoch,
        habit.createdAt.millisecondsSinceEpoch,
      );
      expect(loaded.completedDates, habit.completedDates);
    });
  });
}
