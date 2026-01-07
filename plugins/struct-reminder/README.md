# Struct Reminder Plugin

Reminds Claude to consider using `defstruct` instead of plain maps in Elixir modules.

## Purpose

Elixir structs provide significant advantages over plain maps:
- **Compile-time key validation** - typos caught at compile time, not runtime
- **`@enforce_keys`** - ensure required fields are always provided
- **Pattern matching** - use `%MyStruct{}` for cleaner guards
- **Default values** - optional fields with sensible defaults
- **Documentation** - `@type t` provides clear type specifications

This plugin detects map usage patterns that would benefit from struct definitions and provides a non-blocking reminder.

## How It Works

The plugin uses a PostToolUse hook that triggers after editing `.ex` files. It analyzes the file for:

1. **Map literals with 3+ keys** - suggests a defined shape worth formalizing
2. **Constructor functions** - `new/0`, `build/1`, `create/1`, `init/1` returning maps
3. **Repeated map patterns** - same keys appearing in multiple places
4. **Multiple Map.put/merge** - suggests evolving state that a struct would validate

If patterns are detected and the module doesn't already have `defstruct`, Claude receives a suggestion via `additionalContext`.

## Installation

```bash
/plugin install struct-reminder@deltahedge
```

## Configuration

No configuration required. The hook activates automatically for `.ex` files.

## What Triggers a Reminder

✅ **Will trigger:**
```elixir
defmodule User do
  def new(name, email, age) do
    %{name: name, email: email, age: age, created_at: DateTime.utc_now()}
  end
end
```

❌ **Will NOT trigger:**
```elixir
# Already has defstruct
defmodule User do
  defstruct [:name, :email, :age]
end

# Simple 1-2 key maps (likely intentional)
def config, do: %{timeout: 5000}

# .exs files (configs, tests, scripts)
# test/user_test.exs - not processed
```

## Reminder Format

When triggered, Claude sees:

```
📦 Struct Opportunity Detected

This module uses map patterns that could benefit from `defstruct`:

- Found map literals with 3+ keys
- Found constructor function (new/build/create/init) returning a map

Benefits of using defstruct:
- Compile-time key validation (typos caught at compile time)
- `@enforce_keys` for required fields
- Pattern matching with `%MyStruct{}`
- Default values for optional fields
- Better documentation via `@type t`
```

## Non-Blocking

This hook is **non-blocking** - it provides suggestions but never prevents edits. Claude receives the context and can decide whether a struct is appropriate for the specific use case.

## When NOT to Use Structs

The reminder is a suggestion, not a mandate. Plain maps are still appropriate for:
- Dynamic/unknown keys (API responses, configs)
- Temporary data structures
- Protocol implementations requiring map behavior
- Interop with external systems expecting maps
