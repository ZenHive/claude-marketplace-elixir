# Doctor Plugin Tests

Test suite for the Mix Doctor documentation quality validation plugin.

## Test Structure

```
test/plugins/doctor/
├── README.md
├── test-doctor-hooks.sh      # Main test script
├── precommit-test-fail/      # Project with missing docs (should fail)
│   ├── mix.exs
│   └── lib/
│       └── missing_docs.ex
└── precommit-test-pass/      # Project with proper docs (should pass)
    ├── mix.exs
    └── lib/
        └── documented.ex
```

## Running Tests

```bash
# Run doctor plugin tests
./test/plugins/doctor/test-doctor-hooks.sh

# Run all plugin tests
./test/run-all-tests.sh
```

## Test Cases

1. **Blocks on Doctor violations** - Verifies commits are blocked when `mix doctor` finds documentation issues
2. **Passes on well-documented code** - Verifies commits proceed when documentation is complete
3. **Skips when precommit alias exists** - Defers to precommit plugin if project has precommit alias
4. **Ignores non-commit commands** - Only runs on `git commit` commands
5. **Ignores non-git commands** - Only runs on git commands
6. **Uses git -C flag** - Properly handles `git -C <path> commit` commands
7. **Skips projects without mix_doctor** - Only runs on projects with mix_doctor dependency

## Setup

Before running tests, ensure dependencies are fetched:

```bash
cd test/plugins/doctor/precommit-test-fail && mix deps.get
cd test/plugins/doctor/precommit-test-pass && mix deps.get
```
