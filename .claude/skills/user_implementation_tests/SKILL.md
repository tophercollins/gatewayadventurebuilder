---
name: user_implementation_tests
description: Run integration tests that simulate real user flows against an in-memory SQLite database.
argument-hint: "[scenario_name] — run a specific test file, or omit to run all"
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# User Implementation Tests

Run integration tests that simulate real user flows end-to-end.

## Behavior

1. If an argument is provided (e.g., `create_campaign`), run that specific test:
   ```bash
   flutter test integration_test/<argument>_test.dart
   ```

2. If no argument is provided, run all integration tests:
   ```bash
   flutter test integration_test/
   ```

3. Report results:
   - List each test scenario with pass/fail status
   - On failure, show the relevant error message and stack trace
   - Suggest fixes for common issues (missing keys, async timing, schema mismatches)

## Registered Test Scenarios

| Scenario | File | Description |
|----------|------|-------------|
| `create_campaign` | `integration_test/create_campaign_test.dart` | Creates a new campaign through the full form flow |
| `record_session` | `integration_test/record_session_test.dart` | Full pipeline: record → transcribe → AI → email |

## Test Infrastructure

- **Test helpers:** `integration_test/test_helpers/test_app.dart`
- **Mock helpers:** `integration_test/test_helpers/mock_providers.dart`
- **Database:** In-memory SQLite via `sqflite_common_ffi` with full schema
- **Router:** Fresh `GoRouter` per test via `createAppRouter(initialLocation: ...)`
- **Provider container:** `buildTestContainer(overrides: [...])` for programmatic pipeline tests
- **UI tests:** No provider overrides needed — database injection through `DatabaseHelper.setTestDatabase()` flows through the existing provider chain
- **Pipeline tests:** Override `transcriptionServiceProvider`, `llmServiceProvider`, `emailServiceProvider`, and `connectivityServiceProvider` with mocks
