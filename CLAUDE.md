# Claude Code Project Rules

## TDD Rules

### Test-Driven Development Process

1. **Red**: Write a failing test first
   - Always write or modify tests before making any implementation changes
   - Run tests to confirm they fail for the expected reason
   - Show the failing test output

2. **Green**: Make the test pass
   - Write the minimal code necessary to make the test pass
   - Don't add extra functionality beyond what the test requires

3. **Refactor**: Clean up the code
   - Improve code structure while keeping tests green
   - Ensure all tests still pass after refactoring

### Implementation Guidelines

- No implementation changes without a failing test first
- Tests must fail for the right reason before proceeding
- Always run tests after each change to verify status
- Keep the red-green-refactor cycle tight and focused