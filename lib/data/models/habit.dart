import 'package:hive/hive.dart';

/// Stored habit row. Uses a manual [TypeAdapter] so no code generation step.
class Habit {
  const Habit({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.completedDates = const {},
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  /// Dates on which the habit was completed, stored as `yyyy-MM-dd` strings.
  final Set<String> completedDates;

  bool get isCompletedToday => completedDates.contains(_todayKey());

  int get currentStreak {
    var streak = 0;
    var date = DateTime.now();
    while (completedDates.contains(_dateKey(date))) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    Set<String>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  Habit toggleToday() {
    final key = _todayKey();
    final updated = Set<String>.from(completedDates);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    return copyWith(completedDates: updated);
  }

  static String _todayKey() => _dateKey(DateTime.now());

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final description = reader.readString();
    final createdAtMs = reader.readInt();
    final completedList = reader.readStringList();
    return Habit(
      id: id,
      title: title,
      description: description,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      completedDates: completedList.toSet(),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeStringList(obj.completedDates.toList());
  }
}
