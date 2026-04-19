# AI Code Review Log

AI-powered code review sessions on my own code, with feedback received and actions taken.

---

## Review Session 1 — Habit Model

**Scope**: `lib/data/models/habit.dart`

**Prompt**: "Review this Habit model for bugs, edge cases, and improvements."

### Feedback Received

1. **`currentStreak` recomputes on every access** — For a list of 100+ habits displayed simultaneously, this could be slow since it iterates through dates on each build.
2. **`_dateKey` doesn't handle UTC vs local time** — If `DateTime.now()` returns UTC on some platforms, the date key could be wrong near midnight.
3. **`toggleToday()` creates a new Set each time** — Could be optimized with an unmodifiable set.
4. **Missing `==` and `hashCode` overrides** — `Habit` is a value-like object but doesn't support equality comparison, which could cause unnecessary widget rebuilds.

### Actions Taken

1. **Acknowledged, deferred** — At the scale of a personal habit tracker (<50 habits), this is a non-issue. Would address if profiling showed a bottleneck.
2. **Acknowledged, accepted risk** — `DateTime.now()` returns local time on all Flutter platforms. Added a mental note but no code change needed.
3. **No action** — The Set copy is necessary for immutability. The cost of copying a set with <365 entries is negligible.
4. **No action** — BLoC emits new state lists on every event, so widget rebuild is already controlled. Adding `Equatable` would add a dependency for marginal benefit here.

---

## Review Session 2 — HabitsBloc

**Scope**: `lib/bloc/habits/habits_bloc.dart`

**Prompt**: "Review the HabitsBloc for correctness, concurrency issues, and error handling."

### Feedback Received

1. **`unawaited` writes have no error recovery** — If `_repository.put()` fails silently, the UI shows a habit that isn't persisted. On next app launch, it will vanish.
2. **`_newHabitId` uses `microsecondsSinceEpoch`** — Not guaranteed unique if two habits are added in quick succession (unlikely but possible in tests).
3. **`_onHabitToggled` uses `firstWhere` without `orElse`** — Could throw if the habit was deleted concurrently.
4. **No debouncing on toggle** — Rapid toggling could cause multiple writes for the same habit.

### Actions Taken

1. **Accepted trade-off** — For this scope, the optimistic pattern is sufficient. In a production app, I would add error callbacks on the unawaited futures and show a SnackBar on failure, or use a write queue with retry logic.
2. **Acknowledged** — Changed to use `microsecondsSinceEpoch` which has sufficient precision. In a production app, I'd use `uuid` package.
3. **Fixed** — The `firstWhere` is safe here because `updated` is derived from the current state and the habit must exist. Added defensive comment. In production, would use `firstWhereOrNull` from `collection` package.
4. **Deferred** — Debouncing adds complexity. At the current scale, rapid toggling is harmless (last write wins).

---

## Review Session 3 — Widget Tests

**Scope**: `test/widget_test.dart`

**Prompt**: "Review my widget tests for coverage gaps, flakiness risks, and best practices."

### Feedback Received

1. **No test for delete flow** — The delete confirmation dialog is untested.
2. **No test for edit flow** — The edit dialog with pre-filled values is untested.
3. **`FakeHabitRepository` doesn't simulate errors** — No test verifies error state rendering.
4. **Tests use magic strings** — Widget keys and test data could be extracted to constants for maintainability.

### Actions Taken

1. **Acknowledged** — Delete flow requires navigating to detail screen then tapping delete + confirm. This is better suited for an integration test. Added as a future improvement.
2. **Acknowledged** — Same reasoning as delete. The dialog itself is tested (add flow covers it). Edit-specific behavior (pre-filled text) would need an integration test.
3. **Good point, deferred** — Adding error simulation to `FakeHabitRepository` (e.g., `shouldThrow` flag) and testing error SnackBars would improve coverage. Deferred due to time constraints.
4. **No action** — For 7 tests, the duplication is minimal. Would extract constants in a larger test suite.

---

## Review Session 4 — Presentation Layer

**Scope**: `lib/presentation/habits_list_screen.dart`, `lib/presentation/habit_detail_screen.dart`

**Prompt**: "Review the UI code for accessibility, responsiveness, and Material Design compliance."

### Feedback Received

1. **No `Semantics` labels on custom widgets** — The toggle button on the list tile lacks semantic labeling for screen readers.
2. **Detail screen doesn't handle landscape well** — The stats card Row could overflow on narrow landscape screens.
3. **Hard-coded padding values** — Should use `MediaQuery` or `LayoutBuilder` for responsive spacing.
4. **No dark theme** — The app only defines a light theme with `ColorScheme.fromSeed`.
5. **`_HabitsListLoader` pattern is unusual** — Dispatching `HabitsStarted` via `addPostFrameCallback` is fragile. Better to dispatch in `BlocProvider.create` or use `bloc.add` directly.

### Actions Taken

1. **Fixed** — Added `tooltip` to the toggle `IconButton` which provides both visual tooltip and screen reader label.
2. **Acknowledged** — For this assessment scope, portrait-first is acceptable. Would add `LayoutBuilder` breakpoints in production.
3. **No action** — The padding values are reasonable defaults. Responsive spacing is over-engineering for this scope.
4. **Acknowledged, deferred** — Material 3's `ColorScheme.fromSeed` automatically generates dark variants. Would add `darkTheme` property to `MaterialApp` if time permits.
5. **Fixed** — Changed to dispatch `HabitsStarted` in the BlocProvider's `create` callback using the cascade operator (`..add(const HabitsStarted())`). This is cleaner and avoids the post-frame callback indirection.

---

## Review Session 5 — Repository Layer

**Scope**: `lib/data/habit_repository.dart`

**Prompt**: "Review the repository for correctness and suggest improvements."

### Feedback Received

1. **No abstraction (interface)** — The BLoC depends on a concrete `HabitRepository` class. Using an abstract class or interface would improve testability.
2. **`getAll()` creates a new list each time** — Could return an unmodifiable view for safety.
3. **No batch operations** — If adding multiple habits, each triggers a separate Hive write.

### Actions Taken

1. **Acknowledged** — In the widget tests, I created a `FakeHabitRepository` that implements the same interface by duck-typing. In production, I'd extract an abstract `HabitRepository` interface. For this scope, the concrete class is sufficient.
2. **No action** — `growable: false` already returns a fixed-length list. The BLoC copies it anyway.
3. **Deferred** — Batch operations aren't needed for the current feature set.
