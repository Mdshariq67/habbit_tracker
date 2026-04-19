# Habit Tracker

A simple daily habit tracking app built with Flutter, demonstrating clean architecture, BLoC state management, and local persistence with Hive.

## Features

- Create, edit, and delete daily habits
- Mark habits as complete/incomplete for today
- Track completion streaks and total completions
- Alphabetically sorted habit list
- Material 3 design with responsive UI
- Full error handling with loading states and retry

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.9+ / Dart |
| State Management | flutter_bloc (BLoC pattern) |
| Local Storage | Hive (no code generation) |
| Testing | flutter_test, bloc_test |
| Architecture | BLoC + Repository pattern |

## Project Structure

```
lib/
├── main.dart                          # App entry point, Hive initialization
├── app.dart                           # MaterialApp, BlocProvider setup
├── data/
│   ├── models/
│   │   └── habit.dart                 # Habit model + Hive TypeAdapter
│   └── habit_repository.dart          # Persistence layer (Hive box)
├── bloc/
│   └── habits/
│       ├── habits_bloc.dart           # Business logic (events → states)
│       ├── habits_event.dart          # Load, Add, Delete, Toggle, Update
│       └── habits_state.dart          # Initial, Loading, Loaded, Failure
└── presentation/
    ├── habits_list_screen.dart        # Home screen with habit list
    ├── habit_detail_screen.dart       # Detail screen with stats & actions
    └── add_habit_dialog.dart          # Add/Edit dialog (reusable)

test/
├── habit_model_test.dart              # 10 unit tests for model logic
├── habit_repository_test.dart         # 9 integration tests with real Hive
├── habits_bloc_test.dart              # 8 BLoC event→state tests
└── widget_test.dart                   # 7 widget tests with fake repository
```

## Setup & Run

### Prerequisites

- Flutter SDK 3.9.2 or later
- Dart SDK (bundled with Flutter)

### Install & Run

```bash
# Clone the repository
git clone <repository-url>
cd TECHNICAL-ASSESSMENT

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run all tests
flutter test
```

### Build

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## Testing

The project has **35 tests** across four test files:

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/habits_bloc_test.dart
```

| Test File | Count | What It Tests |
|-----------|-------|---------------|
| `habit_model_test.dart` | 10 | copyWith, streaks, toggleToday, date logic |
| `habit_repository_test.dart` | 9 | CRUD operations, Hive adapter round-trip |
| `habits_bloc_test.dart` | 8 | Event→state transitions, edge cases |
| `widget_test.dart` | 7 | UI flows: empty state, add, edit, navigate, toggle, sort |

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — Design decisions, layer architecture, trade-offs
- [AI_LOG.md](AI_LOG.md) — Chronological AI interaction log (12 entries)
- [REVIEW_LOG.md](REVIEW_LOG.md) — AI code review sessions with responses

## AI Reflection

AI tools (Claude / Cursor) significantly accelerated boilerplate-heavy work: scaffolding the BLoC event/state classes, generating the Hive TypeAdapter, and creating test fixtures. The test scaffolding for `bloc_test` was particularly useful — the AI generated the `setUpAll`/`setUp`/`tearDownAll` Hive lifecycle that would have taken trial-and-error to get right.

However, AI was unreliable for debugging the widget test hang. It confidently attributed the issue to `pumpAndSettle` animations, but the real cause was Hive I/O operations on real threads leaking across test boundaries due to `BlocProvider.dispose()` not awaiting `bloc.close()`. Diagnosing this required understanding Flutter's test zone model, which the AI couldn't reason about accurately. The fix (in-memory fake repository) came from first-principles reasoning, not AI suggestions.

Overall, AI was a 2-3x multiplier on implementation speed, but added negative value when its suggestions were wrong and required time to disprove. The key skill is knowing when to trust AI output (mechanical tasks) versus when to debug independently (framework-level issues).
