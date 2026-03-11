---
description: "Create missing Flutter unit, bloc, widget, and integration tests for untested recent features"
name: "Test Untested Features"
argument-hint: "Describe the last features to validate (files, modules, or user flows)"
agent: "agent"
---
Create and validate tests for the latest features that are still untested in this workspace.

Input:
- Feature scope: ${input:Describe the last untested features}

Requirements:
1. Discover relevant production files tied to the feature scope.
2. Inspect existing test conventions in `test/` and match naming/style.
3. Identify coverage gaps for:
- Happy paths
- Error handling
- State transitions (especially BLoC/Cubit)
- Data/domain contract behavior
4. Create a balanced test set across:
- Unit tests
- BLoC/Cubit tests
- Widget tests
- Integration tests (when flow-level behavior is part of the scope)
5. Add or update test files under `test/` only as needed.
6. Keep tests deterministic (no flaky timing/network assumptions).
7. Run the appropriate test command(s) and report results.

Output format:
1. Coverage summary by feature area.
2. Files created/updated (with short purpose).
3. Test execution results (passed/failed and key failure details).
4. Remaining risk or untested edge cases.

Project context hints:
- Flutter app with Clean Architecture and BLoC.
- Prefer focused unit and bloc tests before broad widget tests.
- If Firebase dependencies are involved, use mocks/fakes instead of live services.