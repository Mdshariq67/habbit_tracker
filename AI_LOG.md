# AI Prompt Log

Chronological log of significant AI interactions during development. Each entry includes the prompt, a summary of the AI response, and my assessment.

---

## Entry 1 — Project Scaffolding & Architecture Selection

**Phase**: Design  
**Prompt**: "I'm building a habit tracker in Flutter for a technical assessment. What architecture pattern would you recommend for a small app with two screens, local persistence, and BLoC state management?"

**AI Response Summary**: Recommended BLoC with three layers (data → bloc → presentation). Suggested Hive for persistence, sealed classes for states, and a single BLoC for the habit list. Provided a folder structure.

**Assessment**: **Accepted**. The layered structure was clean and appropriate for the scope. I adopted the folder layout as-is.

---

## Entry 2 — Habit Model Design

**Phase**: Design  
**Prompt**: "Design a Habit model for a daily habit tracker. It needs an id, title, optional description, creation date, and a way to track which days the habit was completed. I want to compute streaks and check if today is complete."

**AI Response Summary**: Suggested an immutable `Habit` class with `completedDates` as a `Set<String>` using `yyyy-MM-dd` keys. Included `isCompletedToday`, `currentStreak`, `toggleToday()`, and `copyWith()`. Proposed a manual Hive `TypeAdapter`.

**Assessment**: **Accepted with minor modification**. The date key format was good. I adjusted the streak calculation to count backwards from today (AI's version counted forward from the earliest date, which was less useful).

---

## Entry 3 — Hive Adapter: Generated vs Manual

**Phase**: Design  
**Prompt**: "Should I use hive_generator with build_runner, or write a manual TypeAdapter for a single model?"

**AI Response Summary**: For a single model, a manual adapter avoids the `build_runner` dependency and keeps the project simpler. Recommended `build_runner` only if the project has 3+ models.

**Assessment**: **Accepted**. The trade-off was clear and well-reasoned for this scope.

---

## Entry 4 — BLoC Event Handlers with Optimistic UI

**Phase**: Implementation  
**Prompt**: "Write the HabitsBloc with events for load, add, delete, toggle, and update. I want optimistic UI updates."

**AI Response Summary**: Generated a full BLoC with five event handlers. Each mutation handler emitted the new state immediately, then awaited the repository write in a try/catch that would rollback on failure.

**Assessment**: **Modified**. The awaited writes caused test hangs because Hive I/O runs on real threads, and `BlocProvider.dispose()` doesn't await `bloc.close()`. I changed all writes to `unawaited()` — the optimistic state is already emitted, so awaiting adds complexity without user-visible benefit at this scale.

---

## Entry 5 — Detail Screen Layout

**Phase**: Implementation  
**Prompt**: "Design a detail screen for a habit that shows today's status, current streak, total completions, creation date, and has edit/delete/toggle actions."

**AI Response Summary**: Proposed a `Scaffold` with `AppBar` actions (edit, delete), a stats `Card` with three columns (Today, Streak, Total), an info `Card` with metadata, and a `FloatingActionButton.extended` for today's toggle.

**Assessment**: **Accepted**. The layout was well-structured and followed Material 3 conventions. I used it with minimal changes.

---

## Entry 6 — Add/Edit Dialog Reuse

**Phase**: Implementation  
**Prompt**: "I have an add habit dialog. How should I modify it to also work as an edit dialog?"

**AI Response Summary**: Suggested adding optional `initialTitle` and `initialDescription` parameters, an `isEditing` flag to change the dialog title and button label, and returning a `HabitDialogResult` record instead of a plain `String`.

**Assessment**: **Accepted**. Clean approach that avoids duplicating the dialog widget.

---

## Entry 7 — Widget Test Hanging Issue

**Phase**: Debugging  
**Prompt**: "My Flutter widget tests hang after the first test that opens a dialog and submits it. The second test never completes. Tests pass individually."

**AI Response Summary**: AI suggested the hang was caused by `pumpAndSettle` never settling due to `CircularProgressIndicator` animations. Recommended using `pump(Duration)` instead.

**Assessment**: **Rejected**. Switching to `pump(Duration)` didn't fix the issue. The root cause was that Hive's `Box.put()` runs real I/O on a separate thread. The test zone tracks these pending operations, and since `BlocProvider.dispose()` doesn't await `bloc.close()`, the I/O outlives the test and blocks the next one. The fix was using an in-memory `FakeHabitRepository` for widget tests, avoiding real I/O entirely.

---

## Entry 8 — Test Strategy: Unit vs Widget vs Integration

**Phase**: Testing  
**Prompt**: "What tests should I write for a Flutter habit tracker app with BLoC? I need good coverage but the scope is small."

**AI Response Summary**: Suggested four test files: model unit tests (pure logic), repository integration tests (real Hive box), BLoC tests (with `bloc_test`), and widget tests (with fake/mock repository). Recommended testing edge cases like empty titles, streak gaps, and sorted order.

**Assessment**: **Accepted**. The split matched my architecture layers. I added specific edge cases the AI didn't suggest (e.g., streak breaking on gap days, toggle removing today when already completed).

---

## Entry 9 — BLoC Test Setup with Hive

**Phase**: Testing  
**Prompt**: "How do I set up bloc_test with a real Hive box for testing? I need setUp/tearDown that creates temp directories."

**AI Response Summary**: Provided a test scaffold with `setUpAll` creating a temp directory and registering the adapter, `setUp` opening/clearing the box, and `tearDownAll` cleaning up. Used `blocTest` with `seed` for initial state and `verify` for repository assertions.

**Assessment**: **Accepted with modification**. The AI's version used `Hive.initFlutter()` which requires platform channels not available in pure Dart tests. I changed it to `Hive.init(hiveDir.path)` for direct filesystem access.

---

## Entry 10 — Error State UX in List Screen

**Phase**: Implementation  
**Prompt**: "How should I display error states in the habit list screen? I want both an error view and a SnackBar for transient errors."

**AI Response Summary**: Suggested using `BlocConsumer` — the listener shows a SnackBar for transient failures (write errors), while the builder shows a full-screen error with retry button for load failures. Used `HabitsFailure` state for both, with the builder checking if it's a load failure (no previous data) vs a write failure (state goes Loaded → Failure → Loaded).

**Assessment**: **Modified**. The dual-purpose `HabitsFailure` state was confusing. I simplified: the builder always shows the current state (if Failure, show retry screen), and the SnackBar listener fires for any Failure state as a notification. Since writes use optimistic updates and don't emit Failure (they use `unawaited`), the Failure state only appears on load errors in practice.

---

## Entry 11 — README Structure for Assessment

**Phase**: Documentation  
**Prompt**: "Write a README for a Flutter habit tracker technical assessment. It needs setup instructions, tech stack, and a reflection on AI usage."

**AI Response Summary**: Generated a template with sections for overview, features, tech stack, setup, testing, architecture link, and AI reflection.

**Assessment**: **Modified**. The AI's reflection was too generic ("AI helped me code faster"). I rewrote it to be specific about what AI accelerated (boilerplate, test scaffolding) and where human judgment was essential (debugging the test hang, architecture trade-offs).

---

## Entry 12 — Streak Calculation Edge Case

**Phase**: Debugging  
**Prompt**: "My streak calculation counts forward from the first completed date. This means if I have dates [April 1, April 2, April 5, April 19], the streak shows 2 (April 1-2) instead of 1 (just today). How should I fix this?"

**AI Response Summary**: Suggested counting backwards from today — start at `DateTime.now()`, check if each date is in `completedDates`, decrement by one day until a gap is found.

**Assessment**: **Accepted**. The backwards approach correctly computes the *current* streak, which is what users expect. The AI's implementation was correct and concise.
