# Code Review Plugin

Universal code review workflow for staged files. Language-agnostic — works with Elixir, Rust, Go, or any language.

## What It Does

Reviews `git diff --staged` against 5 categories:

1. **Bugs & Logic Errors** — runtime crashes, type confusion, silent failures
2. **Missing Extractions** — code AND data that should be separated out
3. **Missing TODO Markers** — temporary code without `TODO:` for static analysis
4. **Abstraction Opportunities** — 3+ similar patterns that could be unified
5. **Actionable TODOs** — TODOs resolvable now, fixed directly

Each finding is rated 1-10 priority. Actionable items are fixed directly, not just flagged.

## Usage

The skill triggers automatically when you ask Claude to review staged files or perform a code review. You can also invoke it explicitly:

```
/code-review:code-review
```

## Relationship to Language Commands

This skill provides the **workflow** (what to check, in what order, with what output). For deep-dive language-specific checklists, use:

- `/elixir-code-review` — comprehensive Elixir/Phoenix checklist
- `/rust-code-review` — comprehensive Rust checklist

## Installation

```bash
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install code-review@deltahedge
```
