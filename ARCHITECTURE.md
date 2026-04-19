# Architecture Decisions

## Overview

Habit Tracker is a Flutter application following the **BLoC (Business Logic Component)** pattern with a clean separation of concerns across three layers: **data**, **business logic**, and **presentation**.

## Why BLoC?

BLoC was chosen over alternatives (Provider, Riverpod, MobX) for the following reasons:

- **Explicit state transitions**: Events map to states through deterministic handlers, making the flow easy to trace and test.
- **Testability**: `bloc_test` allows testing every event→state transition without needing a widget tree.
- **Separation of concerns**: UI code never touches persistence directly — it dispatches events and reacts to states.
- **Flutter ecosystem maturity**: `flutter_bloc` is well-maintained, widely adopted, and has first-class devtools support.

## Layer Architecture

```
┌─────────────────────────────────┐
│        Presentation Layer       │
│  (Screens, Widgets, Dialogs)    │
├─────────────────────────────────┤
│       Business Logic Layer      │
│   (HabitsBloc, Events, States) │
├─────────────────────────────────┤
│          Data Layer             │
│  (HabitRepository, Habit model) │
│         Hive (local DB)         │
└─────────────────────────────────┘
```

### Data Layer

- **Habit model** — immutable data class with `id`, `title`, `description`, `createdAt`, and `completedDates` (a `Set<String>` of `yyyy-MM-dd` keys). Business logic like `isCompletedToday`, `currentStreak`, and `toggleToday()` lives on the model itself, keeping the BLoC thin.
- **HabitAdapter** — hand-written Hive `TypeAdapter` to avoid `build_runner` / code generation overhead for a small model.
- **HabitRepository** — thin wrapper around `Box<Habit>` providing `getAll`, `getById`, `put`, `update`, and `delete`. Keeps Hive details out of the BLoC.

### Why Hive?

- Zero-setup local persistence (no native configuration or migrations).
- Synchronous reads from an in-memory cache, so `getAll()` is instant.
- Suitable for the small dataset a habit tracker manages.

### Business Logic Layer

- **HabitsBloc** handles five events: `HabitsStarted` (load), `HabitsHabitAdded`, `HabitsHabitDeleted`, `HabitsHabitToggled`, and `HabitsHabitUpdated`.
- **Optimistic UI**: The BLoC emits the new state immediately, then fires the repository write in the background (`unawaited`). This keeps the UI snappy.
- **State sealed classes**: `HabitsInitial`, `HabitsLoading`, `HabitsLoaded`, `HabitsFailure` — exhaustive `switch` in the UI ensures every state is handled.

### Presentation Layer

- **HabitsListScreen** — `BlocConsumer` with a listener for error SnackBars and a builder for the main content (empty, loading, error, or list). A `FloatingActionButton` opens the add/edit dialog.
- **HabitDetailScreen** — reads habit by ID from the BLoC state. Shows stats (today status, streak, total completions), metadata, and exposes edit/delete/toggle actions.
- **AddHabitDialog** — reused for both creating and editing habits, accepting optional initial values.

## State Management Flow

```
User taps "Complete" → HabitsHabitToggled(id) event
  → BLoC toggles the habit's completedDates
  → Emits HabitsLoaded(updatedList)
  → UI rebuilds with check icon filled
  → Repository.update() fires in background
```

## Testing Strategy

| Layer | Test file | Approach |
|-------|-----------|----------|
| Model | `habit_model_test.dart` | Pure unit tests for `copyWith`, `toggleToday`, `currentStreak`, `isCompletedToday` |
| Repository | `habit_repository_test.dart` | Integration tests with a real temp Hive box |
| BLoC | `habits_bloc_test.dart` | `bloc_test` — seed state, dispatch event, assert emitted states |
| UI | `widget_test.dart` | Widget tests with an in-memory `FakeHabitRepository` to avoid real I/O |

## Trade-offs & Alternatives Considered

| Decision | Alternative | Rationale |
|----------|-------------|-----------|
| Manual Hive adapter | `hive_generator` + `build_runner` | Avoids code-gen complexity for a single small model |
| Optimistic writes (`unawaited`) | Awaited writes with rollback | Keeps UI instant; rollback adds complexity beyond scope |
| Single BLoC for all habits | Separate BLoCs per feature | App scope is small; one BLoC keeps state consistent |
| `Set<String>` for completed dates | `List<DateTime>` | String keys are simpler to compare and serialize; avoids timezone issues |
