---
name: phoenix-setup
description: Phoenix project setup and authentication configuration. This skill should be used when creating a Phoenix project, generating authentication with phx.gen.auth (CRITICAL --live flag), adding Sobelow or LiveDebugger, configuring .formatter.exs with HTMLFormatter, or setting up Tidewave endpoint plug. Use after elixir-setup for Phoenix-specific additions.
allowed-tools: Read, Bash, Grep, Glob
---

# Phoenix Project Setup

Phoenix-specific dependencies and configuration. Use **after** `elixir-setup` for the base tooling.

## Scope

WHAT THIS SKILL DOES:
  ✓ Phoenix-specific deps (Sobelow, LiveDebugger)
  ✓ .formatter.exs with HTMLFormatter configuration
  ✓ Tidewave endpoint plug for Phoenix
  ✓ Authentication generation with `--live` flag

WHAT THIS SKILL DOES NOT DO:
  ✗ Base Elixir deps: Styler, Credo, Dialyxir, Doctor (→ elixir-setup)
  ✗ Phoenix framework patterns (→ phoenix-patterns)
  ✗ Phoenix Scope usage (→ phoenix-scope)

## When to use this skill

- Creating a new Phoenix project
- Generating authentication with `phx.gen.auth`
- Adding Sobelow or LiveDebugger
- Configuring `.formatter.exs` with HTMLFormatter
- Setting up Tidewave endpoint plug for Phoenix

## ALWAYS Use --live Flag for Authentication

**CRITICAL:** When generating authentication with Phoenix 1.8+, **ALWAYS** use the `--live` flag:

```bash
# CORRECT - Generates LiveView-based auth with proper scoping configuration
mix phx.gen.auth Accounts User users --live

# WRONG - Generates controller-based auth WITHOUT LiveView scoping
mix phx.gen.auth Accounts User users
```

**Why this matters:**
- **Without `--live`**: Does NOT configure automatic scoping for LiveView resources
  - Future `mix phx.gen.live` commands won't be scoped to current user
  - Manual security code required for every resource
  - Scope module/configuration incomplete for LiveView
- **With `--live`**: Configures proper scoping in `config/config.exs`
  - All subsequent `phx.gen.live` commands automatically generate scoped code
  - Context functions auto-accept `%Scope{}` parameter
  - Queries auto-filter by `user_id`
  - Security by default, zero manual work

**The Real Problem:**
Without `--live`, the scope configuration is incomplete. When you later run `mix phx.gen.live RealEstate Property properties ...`, the generated code won't include user scoping. This creates a **major security vulnerability** - users can see/edit each other's data.

**Common mistake:** Forgetting the `--live` flag requires complete redo of auth setup and re-cherry-picking all subsequent work.

## Base Setup

For standard Elixir tooling (Styler, Credo, Dialyxir, Doctor, Tidewave, ex_unit_json, dialyzer_json), see `elixir-setup`.

## Phoenix-Specific Dependencies

Add these **in addition to** the base deps from `elixir-setup`:

| Dep | Purpose |
|-----|---------|
| sobelow | Security-focused analysis for Phoenix (SQL injection, XSS, CSRF) |
| live_debugger | Visual LiveView debugging UI at localhost:4007 |

```elixir
# Add to existing deps (after base deps from elixir-setup)
{:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
{:live_debugger, "~> 0.5", only: :dev}
```

**Note:** Phoenix projects do NOT need `{:bandit, ...}` - Phoenix already has an HTTP server.

## .formatter.exs (Phoenix with Styler)

```elixir
[
  import_deps: [:phoenix],
  plugins: [Styler, Phoenix.LiveView.HTMLFormatter],  # Add Styler BEFORE HTMLFormatter
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"]
]
```

## Tidewave for Phoenix

Add to `lib/my_app_web/endpoint.ex` - **ABOVE** the `if code_reloading?` block:

```elixir
# Tidewave dev tools
if Code.ensure_loaded?(Tidewave) do
  plug Tidewave
end

# Code reloading can be explicitly enabled under the
# :code_reloader configuration of your endpoint.
if code_reloading? do
  ...
end
```

## LiveDebugger Setup

Add to `lib/my_app_web/components/layouts/root.html.heex`:
```heex
<head>
  <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
  ...
</head>
```

After starting your app, LiveDebugger runs at `http://localhost:4007`. See [LiveDebugger docs](https://hexdocs.pm/live_debugger/welcome.html) for full usage.

**LiveDebugger Limitation with `web` command**: The `web` command creates a separate browser session, so LiveViews accessed via `web http://localhost:4000` won't appear in LiveDebugger's "Active LiveViews" list. To debug LiveViews with LiveDebugger:
- Open `http://localhost:4007` directly in your browser (same browser session as localhost:4000)
- Click "Refresh" under Active LiveViews to see current LiveViews

## Phoenix-Specific Commands

In addition to the standard commands from `elixir-setup`, Phoenix projects should run:

```bash
mix sobelow  # Run Phoenix security analysis
```
