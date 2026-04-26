---
name: oxc
description: "OXC Elixir bindings for parsing, transforming, bundling, and minifying JavaScript/TypeScript via Rust NIFs. ALWAYS use this skill when working with JS/TS source analysis, ESTree AST navigation, class hierarchy extraction, code generation from AST, TypeScript-to-JavaScript transformation, or any static analysis of JavaScript/TypeScript files. Covers parse, transform, bundle, minify, imports, walk/postwalk/collect traversal, patch_string, and the recursive value-extraction pattern. Use this even if you think you know OXC — it contains runtime-verified corrections to common misconceptions."
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/oxc.md — do not edit manually -->

## OXC: Parse, Transform, and Bundle JS/TS on the BEAM

Rust NIF bindings for the [OXC](https://oxc.rs) toolchain. Parses, transforms, minifies, and bundles JS/TS on the BEAM — no Node.js.

**Min version: `{:oxc, "~> 0.10"}`.** 0.10 adds AST codegen (`OXC.codegen/1`, `OXC.codegen!/1`), placeholder templating (`OXC.bind/2`, `OXC.splice/3`), and the `:external` bundle option. 0.9 adds `OXC.Format` (oxfmt as a Rust NIF — see Format section) and `OXC.Lint.run!/2,3` bang variants. 0.7.2 adds `OXC.transform_many/2` (parallel via rayon). 0.8 added `OXC.Lint` (oxlint's 650+ rules + custom Elixir rules via `OXC.Lint.Rule`). 0.7 broke vs 0.6: AST `:type`/`:kind` values are now snake_case atoms, error tuples are `{:error, [%{message: String.t()}]}`, bang functions raise `OXC.Error` (not `RuntimeError`). On 0.6 match strings (`"ImportDeclaration"`); on 0.7+ match atoms (`:import_declaration`).

**Does NOT cover:** runtime JS execution (→ QuickBEAM), installing npm packages (→ `mix npm.install`), frontend build + HMR (→ Volt).

### Parsing

```elixir
# Parse JS or TS to ESTree AST (maps with atom keys AND atom :type/:kind values)
# File extension determines language: .ts, .tsx, .js, .jsx
{:ok, ast} = OXC.parse(source, "file.ts")
ast.type  # => :program

{:error, [%{message: msg} | _]} = OXC.parse(bad_source, "file.ts")

# Raising variant — raises OXC.Error
ast = OXC.parse!(source, "file.ts")

# Fast syntax validation (no AST allocation)
true = OXC.valid?(source, "file.ts")
```

AST uses **atom keys** AND **atom values** for `:type`/`:kind` (`:import_declaration`, `:variable_declaration`, …).

### Transform (TS → JS)

```elixir
# Strip type annotations AND interfaces, transform JSX
{:ok, js} = OXC.transform(source, "file.ts")
# "const x: number = 1; interface Foo { bar: string }" → "const x = 1;\n"

# Options
{:ok, js} = OXC.transform(source, "file.tsx",
  jsx: :automatic,           # :automatic | :classic
  jsx_factory: "h",          # custom JSX factory (classic mode)
  jsx_fragment: "Fragment",  # custom fragment
  import_source: "preact",   # JSX import source (automatic mode)
  target: "es2020",          # target ES version
  sourcemap: true            # generate source map
)
```

### Codegen (0.10+)

`OXC.codegen/1` emits JavaScript source from an ESTree AST. Handles precedence, indentation, semicolon insertion. **Roundtripping TS through codegen emits JS** — TypeScript type annotations, interfaces, and `as`/satisfies expressions are stripped.

```elixir
{:ok, ast} = OXC.parse("const x: number = 40 + 2;", "f.ts")
{:ok, "const x = 40 + 2;\n"} = OXC.codegen(ast)   # TS type annotation gone

js = OXC.codegen!(ast)                             # bang variant
```

Works on hand-built ASTs too — manually construct a `:program` with `.body` and codegen will emit it, as long as each node has its required ESTree fields.

### Bind & Splice — Placeholder Templating (0.10+)

AST-level string templating. `$placeholder` identifiers in the source are replaced with Elixir values, structurally (not by string substitution), so you can't build syntactically invalid output.

```elixir
{:ok, ast} = OXC.parse("const x = $v;", "t.js")

# Bindings is a keyword list, NOT a map
OXC.bind(ast, v: {:literal, 42})    |> OXC.codegen!()  # => "const x = 42;\n"
OXC.bind(ast, v: "userId")          |> OXC.codegen!()  # => "const x = userId;\n"   (identifier rename)
OXC.bind(ast, v: {:expr, "40 + 2"}) |> OXC.codegen!()  # => "const x = 40 + 2;\n"   (parsed sub-AST)
OXC.bind(ast, v: other_ast_node)    |> OXC.codegen!()  # raw AST node (must have :type)
```

Binding value forms:
- **string** — replaced as identifier name (rename)
- **`{:literal, v}`** — replaced with a literal node. Maps/lists recursively become JS object/array literals.
- **`{:expr, "code"}`** — parsed as a JS expression, inserted as a sub-AST
- **raw AST node** (map with `:type`) — spliced directly

`splice/3` replaces `$name` *statements*, shorthand object *properties*, or array *elements* with one or more nodes (strings auto-parse as JS):

```elixir
{:ok, ast} = OXC.parse("function f() { $body }", "t.js")
OXC.splice(ast, :body, ["const x = 1;", "return x;"]) |> OXC.codegen!()
# => "function f() {\n\tconst x = 1;\n\treturn x;\n}\n"
```

`bind` = substitute at expression positions. `splice` = substitute at statement/list positions.

### Minify

```elixir
{:ok, minified} = OXC.minify(source, "file.js")                     # DCE, constant folding, whitespace
{:ok, minified} = OXC.minify(source, "file.js", mangle: false)      # keep original names
```

### Format (0.9+)

`OXC.Format` wraps oxfmt (the OXC formatter, separate Rust NIF `oxc_fmt_nif`). Prettier-compatible output defaults; no Node.js needed.

```elixir
{:ok, "const x = 1 + 2;\nfunction foo(a, b) {\n  return a + b;\n}\n"} =
  OXC.Format.run("const   x=1 +2 ; function  foo(   a,b) {return a+b ;}", "t.js")

formatted = OXC.Format.run!(source, "t.ts")   # bang variant — raises OXC.Error
```

Options mirror Prettier-ish knobs (`print_width`, `tab_width`, `use_tabs`, `single_quote`, `trailing_comma`, `semi`). `oxc_fmt_nif` ships precompiled for aarch64/x86_64 glibc + darwin — **no musl builds**, so on Alpine you'll compile from source (Rust toolchain required).

### Transform Many (0.7.2+)

Parallel transform via a Rust (rayon) thread pool — significantly faster than `Task.async_stream` for many files since work is distributed across OS threads without BEAM scheduling overhead.

```elixir
# Footgun: {source, filename} — OPPOSITE order from OXC.bundle/2 ({filename, source})
results = OXC.transform_many([
  {"const a: number = 1;", "a.ts"},
  {"const b: string = 'x';", "b.ts"}
])
# => [ok: "const a = 1;\n", ok: "const b = \"x\";\n"]

# Shared opts apply to all files
OXC.transform_many(inputs, jsx: :automatic, target: "es2020")
```

Each result is `{:ok, code}`, `{:ok, %{code:, sourcemap:}}` (with `sourcemap: true`), or `{:error, errors}`. Preserves input order.

### Bundle

```elixir
# Bundle multiple TS/JS modules — :entry is REQUIRED
{:ok, js} = OXC.bundle(
  [
    {"event.ts", event_source},
    {"target.ts", target_source}  # can import from './event'
  ],
  entry: "target.ts"
)

# Full options (v0.7+)
{:ok, js} = OXC.bundle(files,
  entry: "main.ts",          # REQUIRED — entry module filename from files
  format: :iife,             # :iife (default) | :esm | :cjs
  minify: true,
  treeshake: true,           # NEW in 0.7: remove unused exports
  preamble: "const { ref } = Vue;",  # NEW in 0.7: code injected at top of IIFE body
  external: ["react", "scheduler"],  # NEW in 0.10: preserve as `import` in output (bare ESM
                                     # specifiers auto-detect; this is for cases auto-detect misses)
  banner: "/* v1.0 */",
  footer: "/* end */",
  define: %{"process.env.NODE_ENV" => ~s("production")},
  sourcemap: true,           # returns %{code: ..., sourcemap: ...} instead of string
  drop_console: true,
  jsx: :automatic,
  target: "es2020"
)
```

### Imports

```elixir
# Fast path — source strings only (type-only imports excluded)
{:ok, ["vue", "axios"]} = OXC.imports(source, "file.ts")

# 0.7+: collect_imports/2 — with type info + byte offsets
{:ok, imports} = OXC.collect_imports(source, "file.ts")
# => [%{specifier: "vue", type: :static, kind: :import, start: 19, end: 24}, ...]
# Fields: :specifier, :type (:static | :dynamic), :kind (:import | :export | :export_all),
#          :start, :end (byte offsets, including quotes)
```

### Rewrite Specifiers (0.7+)

```elixir
# Callback MUST return {:rewrite, new} | :keep — bare string raises CaseClauseError.
{:ok, rewritten} = OXC.rewrite_specifiers(source, "file.ts", fn
  "vue" -> {:rewrite, "/@vendor/vue.js"}
  _ -> :keep
end)
```

Cleaner than parse → collect → patch for simple rewrites.

### Patch String

```elixir
patched = OXC.patch_string(source, [
  %{start: 10, end: 20, change: "replacement"},
  %{start: 30, end: 35, change: ""}            # deletion
])
```

Use `.start`/`.end` from AST nodes — byte offsets. Patches can be in any order (sorted internally). For specifier rewrites, prefer `rewrite_specifiers/3`.

### AST Navigation

Pattern-match on atoms:

```elixir
{:ok, ast} = OXC.parse(source, "file.ts")

# ast.body is a list of top-level statements
# `export default class` → top is :export_default_declaration with .declaration
export = Enum.find(ast.body, &(&1.type == :export_default_declaration))
class = export.declaration
# Plain class (no export default) → :class_declaration directly:
class = Enum.find(ast.body, &(&1.type == :class_declaration))

class.id.name           # nil if anonymous
class.superClass.name   # nil if no extends
class.body.body         # class members

methods = Enum.filter(class.body.body, &(&1.type == :method_definition))
# method.key.name, method.value.async, .params, .body.body
# FunctionExpression (method.value) keys: :async, :id, :params, :body, :generator,
# :declare, :typeParameters, :expression, :returnType
```

#### Key ESTree Node Types (atoms 0.7+)

String-to-atom mapping: `"FooBar"` → `:foo_bar` (PascalCase → snake_case).

| Atom (0.7+) | String (0.6-) | Key Fields |
|-------------|---------------|------------|
| `:program` | `"Program"` | `.body` |
| `:export_default_declaration` | `"ExportDefaultDeclaration"` | `.declaration` |
| `:export_named_declaration` | `"ExportNamedDeclaration"` | `.declaration`, `.specifiers`, `.source` |
| `:class_declaration` | `"ClassDeclaration"` | `.id.name`, `.superClass`, `.body.body` |
| `:method_definition` | `"MethodDefinition"` | `.key.name`, `.value` (function_expression) |
| `:function_expression` | `"FunctionExpression"` | `.async`, `.params`, `.body.body`, `.returnType` |
| `:function_declaration` | `"FunctionDeclaration"` | `.id.name`, `.params`, `.body.body` |
| `:arrow_function_expression` | `"ArrowFunctionExpression"` | `.async`, `.params`, `.body` |
| `:object_expression` | `"ObjectExpression"` | `.properties` |
| `:array_expression` | `"ArrayExpression"` | `.elements` |
| `:literal` | `"Literal"` | `.value` (string/number/boolean/null) |
| `:identifier` | `"Identifier"` | `.name` |
| `:call_expression` | `"CallExpression"` | `.callee`, `.arguments` |
| `:unary_expression` | `"UnaryExpression"` | `.operator`, `.argument` |
| `:member_expression` | `"MemberExpression"` | `.object`, `.property` |
| `:return_statement` | `"ReturnStatement"` | `.argument` |
| `:import_declaration` | `"ImportDeclaration"` | `.source.value`, `.specifiers` |
| `:variable_declaration` | `"VariableDeclaration"` | `.declarations`, `.kind` (`:var`/`:let`/`:const`) |

Unknown atom for a type? Run `OXC.parse(source, "file.ts")` and inspect `ast.body |> hd() |> Map.get(:type)` — runtime is authoritative.

#### Type Annotations (TypeScript)

Nested under `.typeAnnotation.typeAnnotation`:

```elixir
# function(x: string)
type_name = get_in(param, [:typeAnnotation, :typeAnnotation, :typeName, :name])
```

### Traversal

```elixir
# walk — side-effects only, returns :ok
:ok = OXC.walk(ast, fn
  %{type: :call_expression, callee: c} -> IO.inspect(c)
  _ -> :ok
end)

# postwalk — depth-first post-order (children before parents)
transformed = OXC.postwalk(ast, fn
  %{type: :identifier, name: "old"} = node -> %{node | name: "new"}
  node -> node
end)

# postwalk with accumulator
{_ast, patches} = OXC.postwalk(ast, [], fn
  %{type: :import_declaration, source: %{value: "vue"} = src} = node, acc ->
    {node, [%{start: src.start, end: src.end, change: "'/@vendor/vue.js'"} | acc]}
  node, acc -> {node, acc}
end)
# For this specific rewrite, prefer OXC.rewrite_specifiers/3.

# collect — {:keep, value} collects, :skip ignores
method_names = OXC.collect(ast, fn
  %{type: :method_definition, key: %{name: name}} -> {:keep, name}
  _ -> :skip
end)
```

### Lint (0.8+)

`OXC.Lint` wraps oxlint (650+ rules, Rust-speed) and lets you add Elixir-side custom rules that walk the same atom-keyed AST `OXC.parse/2` returns.

```elixir
# Built-ins only — severity is :allow | :warn | :deny
{:ok, diags} = OXC.Lint.run(source, "app.tsx",
  plugins: [:react, :typescript],
  rules: %{"no-debugger" => :deny, "no-console" => :warn}
)

# 0.9+: bang variant — raises OXC.Error on parse failure, returns diags list directly
diags = OXC.Lint.run!(source, "app.tsx", rules: %{"no-debugger" => :deny})

# Diagnostic shape (rule is namespaced — "eslint(no-debugger)"):
# %{rule: "eslint(no-debugger)", severity: :deny, message: "...",
#   span: {start, end}, labels: [{s, e}], help: String.t() | nil}

# Custom Elixir rules — module implements OXC.Lint.Rule (meta/0 + run/2)
{:ok, diags} = OXC.Lint.run(source, "app.ts",
  custom_rules: [{MyApp.NoConsoleLog, :warn}]
)
```

Plugin atoms: `:react`, `:typescript`, `:unicorn`, `:import`, `:jsdoc`, `:jest`, `:vitest`, `:jsx_a11y`, `:nextjs`, `:react_perf`, `:promise`, `:node`, `:vue`, `:oxc`. Default is oxlint's correctness set (no plugin flag needed for rules like `no-debugger`).

`:fix` option computes suggested fixes; `:settings` passes arbitrary context to custom rules.

### Recipes

**Recursive AST value extraction** (object_expression/array_expression/literal → Elixir):

```elixir
extract = fn
  %{type: :literal, value: v}, _r -> v
  %{type: :object_expression, properties: props}, r ->
    Map.new(props, fn p ->
      key = Map.get(p.key, :name) || to_string(Map.get(p.key, :value, "?"))
      {key, r.(p.value, r)}
    end)
  %{type: :array_expression, elements: els}, r -> Enum.map(els, &r.(&1, r))
  %{type: :identifier, name: "undefined"}, _r -> :undefined
  %{type: :identifier, name: n}, _r -> {:ref, n}
  %{type: :unary_expression, operator: "-", argument: %{value: v}}, _r -> -v
  %{type: :call_expression} = node, _r ->
    callee = get_in(node, [:callee, :property, :name]) || "unknown"
    {:call, callee, Enum.map(node.arguments, &Map.get(&1, :value, "?"))}
  %{type: t}, _r -> {:ast, t}
  nil, _r -> nil
end

value = extract.(config_node, extract)   # Y-combinator: anon fns can't self-recurse
```

**Find method in class:**
```elixir
export = Enum.find(ast.body, &(&1.type == :export_default_declaration))
methods = Enum.filter(export.declaration.body.body, &(&1.type == :method_definition))
target = Enum.find(methods, &(&1.key.name == "describe"))
```

**Find property in ObjectExpression** (keys can be identifier `.name` or literal `.value`):
```elixir
Enum.find(object_node.properties, fn p ->
  (Map.get(p.key, :name) || Map.get(p.key, :value)) == "id"
end)
```

### Error Handling (0.7+)

```elixir
case OXC.parse(source, "file.ts") do
  {:ok, ast} -> process(ast)
  {:error, errors} ->
    for %{message: msg} <- errors, do: Logger.warning("OXC: #{msg}")
end

try do
  OXC.parse!(source, "file.ts")
rescue
  e in OXC.Error -> Logger.error(Exception.message(e))   # was RuntimeError in 0.6
end
```

### Migrating 0.6 → 0.7

1. String `:type`/`:kind` → snake_case atoms: `"ClassDeclaration"` → `:class_declaration`
2. `rescue RuntimeError` → `rescue OXC.Error`
3. `{:error, msg}` → `{:error, [%{message: msg} | _]}`
4. Consider `OXC.rewrite_specifiers/3` for import rewrites
5. Consider `OXC.collect_imports/2` when you need type info or offsets

### Migrating 0.8 → 0.10

No breaking API changes — purely additive. If you were hand-rolling AST→string emission via `patch_string` + `postwalk`, switch to `OXC.codegen/1`. If you have import-rewriting macros that substitute identifier strings into source templates, switch to `OXC.bind/2` + `OXC.codegen/1` (structural instead of string-concat, so ill-typed substitutions fail visibly at bind time rather than producing syntactically invalid output). Custom `OXC.Lint.Rule` modules keep working unchanged.

### Common Pitfalls

| Problem | Cause | Fix |
|---|---|---|
| `FunctionClauseError` after upgrade | Still matching string types | Swap to atoms |
| `KeyError` on node | Optional fields missing | Match `.type` first, use `Map.get/3` for optionals |
| `.superClass` is nil | No `extends` | Check `is_nil(class.superClass)` |
| Property key access fails | Keys can be identifier or literal | `p.key.name \|\| p.key.value` |
| Wrong file extension | Extension picks parser | `.ts`, `.tsx`, `.js`, `.jsx` |
| Y-combinator forgotten | Anon fns can't self-recurse | Pass `fn` as arg |
| `bundle/2` empty | Missing `:entry` | Required since 0.6 |
| `transform_many`/`bundle` arg order reversed | `transform_many` is `{source, filename}`; `bundle` is `{filename, source}` | Remember: bundle files are virtual project *files* (filename first); transform inputs are *sources* being labeled |
| `OXC.bind` `FunctionClauseError` | Passed a map `%{v: ...}` | Bindings must be a keyword list `[v: ...]` |
| TS types vanish after `codegen` roundtrip | `codegen` emits JS, not TS | Expected — codegen is not an identity function on TS |

### DO NOT

1. Don't use string keys — always atom-keyed maps (`node.type`, not `node["type"]`).
2. Don't parse just to validate — use `OXC.valid?/2`.
3. Don't parse just for imports — use `OXC.imports/2` or `OXC.collect_imports/2`.
4. Don't hand-roll import rewrites — `OXC.rewrite_specifiers/3` is a single pass.
5. Don't use OXC to run JS — static analysis only. Use QuickBEAM for runtime.

### Performance

| Operation | ~Time |
|---|---|
| Parse 14.5k-line TS | 43ms |
| Transform TS→JS | 10ms |
| Minify | 5ms |
| `valid?` | 20ms |
| `imports` | 15ms |
| `collect_imports` | 20ms |

Rust NIF, CPU-bound. For batch transform, prefer `OXC.transform_many/2` (rayon thread pool, 0.7.2+) over `Task.async_stream` — distributes across OS threads without BEAM scheduling overhead.
