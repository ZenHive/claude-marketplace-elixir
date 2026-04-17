---
name: oxc
description: "OXC Elixir bindings for parsing, transforming, bundling, and minifying JavaScript/TypeScript via Rust NIFs. ALWAYS use this skill when working with JS/TS source analysis, ESTree AST navigation, class hierarchy extraction, code generation from AST, TypeScript-to-JavaScript transformation, or any static analysis of JavaScript/TypeScript files. Covers parse, transform, bundle, minify, imports, walk/postwalk/collect traversal, patch_string, and the recursive value-extraction pattern. Use this even if you think you know OXC — it contains runtime-verified corrections to common misconceptions."
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/oxc.md — do not edit manually -->

## OXC: Parse, Transform, and Bundle JS/TS on the BEAM

Rust NIF bindings for the [OXC](https://oxc.rs) JavaScript toolchain. Parses, transforms, minifies, and bundles JavaScript and TypeScript entirely on the BEAM — no Node.js required.

**Minimum version documented here: `{:oxc, "~> 0.7"}`.** v0.7.0 introduced breaking changes vs 0.6.x — AST `:type`/`:kind` values are now snake_case atoms (not strings), error tuples are `{:error, [%{message: String.t()}]}`, and bang functions raise `OXC.Error` (not `RuntimeError`). If your project is still on 0.6.x, match strings (`type: "ImportDeclaration"`); if on 0.7+, match atoms (`type: :import_declaration`).

### Scope

WHAT THIS COVERS:
  - Parsing JS/TS to ESTree AST and navigating the result
  - AST traversal (walk, postwalk, collect) and value extraction
  - Transforming TypeScript to JavaScript
  - Bundling multiple modules into a single IIFE/ESM/CJS
  - Minifying JS for production
  - Extracting import sources (with or without type info)
  - Rewriting import/export specifiers in a single pass
  - Source patching via byte offsets

WHAT THIS DOES NOT COVER:
  - Running JS code at runtime (use QuickBEAM)
  - Installing npm packages (use npm_ex: `mix npm.install`)
  - Frontend build pipelines with HMR (use Volt)

### API Reference

#### Parsing

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

The AST is a map with **atom keys** (`ast.type`, `ast.body`, `node.name`, …) AND **atom values** for `:type` and `:kind` fields (`:import_declaration`, `:variable_declaration`, `:function_expression`, …).

#### Transform (TS to JS)

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

#### Minify

```elixir
# Dead code elimination, constant folding, whitespace removal
{:ok, minified} = OXC.minify(source, "file.js")

# Disable identifier mangling (keeps original names)
{:ok, minified} = OXC.minify(source, "file.js", mangle: false)
```

#### Bundle

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
  banner: "/* v1.0 */",
  footer: "/* end */",
  define: %{"process.env.NODE_ENV" => ~s("production")},
  sourcemap: true,           # returns %{code: ..., sourcemap: ...} instead of string
  drop_console: true,
  jsx: :automatic,
  target: "es2020"
)
```

#### Imports

```elixir
# Fast path: just the source strings (type-only imports excluded)
{:ok, sources} = OXC.imports(source, "file.ts")
# "import { ref } from 'vue'; import type { Ref } from 'vue'; import axios from 'axios'"
# => ["vue", "axios"]

# NEW in 0.7: collect_imports/2 — source strings WITH type info and byte offsets
{:ok, imports} = OXC.collect_imports(source, "file.ts")
# => [
#   %{specifier: "vue", type: :static, kind: :import, start: 19, end: 24},
#   %{specifier: "./bar", type: :static, kind: :export, start: 49, end: 56},
#   %{specifier: "./lazy", type: :dynamic, kind: :import, start: 70, end: 78}
# ]
# Fields: :specifier, :type (:static | :dynamic), :kind (:import | :export | :export_all),
#          :start, :end (byte offsets including quotes)
```

#### Rewrite Specifiers (NEW in 0.7)

```elixir
# Rewrite all import/export specifier strings in a single pass
# Callback MUST return {:rewrite, new_specifier} | :keep — NOT a bare string.
# Returning a bare string raises CaseClauseError.
{:ok, rewritten} = OXC.rewrite_specifiers(source, "file.ts", fn
  "vue" -> {:rewrite, "/@vendor/vue.js"}
  "./" <> _ -> :keep
  _ -> :keep
end)
# Cleaner than parse → collect imports → patch_string for simple rewrites.
```

#### Patch String

```elixir
# Apply byte-offset patches to source code
patched = OXC.patch_string(source, [
  %{start: 10, end: 20, change: "replacement"},
  %{start: 30, end: 35, change: ""}  # deletion
])
```

Use `.start` and `.end` fields from AST nodes directly — they are byte offsets. Patches can be in any order; the function sorts internally. For simple import rewrites, prefer `rewrite_specifiers/3` (above).

### AST Navigation

The AST uses **atom keys** AND **atom `:type`/`:kind` values**. Pattern-match on atoms:

```elixir
{:ok, ast} = OXC.parse(source, "file.ts")

# Top-level: ast.body is a list of statements
# If file has `export default class`, top-level is :export_default_declaration:
export = Enum.find(ast.body, &(&1.type == :export_default_declaration))
class = export.declaration

# If file has a plain class (no export default), it's :class_declaration directly:
class = Enum.find(ast.body, &(&1.type == :class_declaration))

# Class structure
class.id.name                    # class name (nil if anonymous)
class.superClass.name            # parent class name (nil if no extends)
class.body.body                  # list of class members

# Methods
methods = Enum.filter(class.body.body, &(&1.type == :method_definition))
method.key.name                  # method name
method.value.async               # boolean
method.value.params              # parameter list
method.value.body.body           # list of statements in method body

# FunctionExpression keys (method.value):
# :async, :id, :params, :body, :generator, :declare,
# :typeParameters, :expression, :returnType
```

#### Key ESTree Node Types (atoms in 0.7+)

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

Don't have the atom for a node type you're matching? Run `OXC.parse(source, "file.ts")` and inspect `ast.body |> hd() |> Map.get(:type)` — the runtime is authoritative.

#### Type Annotations (TypeScript)

Type info is nested under `.typeAnnotation.typeAnnotation`:

```elixir
# Parameter type: function(x: string)
type_name = get_in(param, [:typeAnnotation, :typeAnnotation, :typeName, :name])
# => "string" or a custom type name like "Str"
```

### AST Traversal

#### walk — Visit Every Node (Side-Effects Only)

```elixir
# Returns :ok — walk is for side effects, not transformation
:ok = OXC.walk(ast, fn
  %{type: :call_expression, callee: c} -> IO.inspect(c)
  _ -> :ok
end)
```

#### postwalk — Depth-First Post-Order

```elixir
# Transform nodes bottom-up (children visited before parents)
transformed = OXC.postwalk(ast, fn
  %{type: :identifier, name: "old"} = node -> %{node | name: "new"}
  node -> node
end)

# With accumulator — collect data during traversal
{_ast, patches} = OXC.postwalk(ast, [], fn
  %{type: :import_declaration, source: %{value: "vue"} = src} = node, acc ->
    {node, [%{start: src.start, end: src.end, change: "'/@vendor/vue.js'"} | acc]}
  node, acc ->
    {node, acc}
end)
patched = OXC.patch_string(source, patches)
```

(For this specific rewrite, prefer `OXC.rewrite_specifiers/3`.)

#### collect — Filter and Extract

```elixir
# Return {:keep, value} to collect, :skip to ignore
method_names = OXC.collect(ast, fn
  %{type: :method_definition, key: %{name: name}} -> {:keep, name}
  _ -> :skip
end)
# => ["describe", "fetchTicker", "fetchBalance", ...]

identifiers = OXC.collect(ast, fn
  %{type: :identifier, name: n} -> {:keep, n}
  _ -> :skip
end)
```

### Recipes

#### Recursive AST Value Extraction

Convert AST subtrees (object_expression, array_expression, literal) back to Elixir values. Standard pattern for extracting configuration objects:

```elixir
extract = fn
  %{type: :literal, value: v}, _r -> v
  %{type: :object_expression, properties: props}, r ->
    Map.new(props, fn p ->
      key = Map.get(p.key, :name) || to_string(Map.get(p.key, :value, "?"))
      {key, r.(p.value, r)}
    end)
  %{type: :array_expression, elements: els}, r ->
    Enum.map(els, &r.(&1, r))
  %{type: :identifier, name: "undefined"}, _r -> :undefined
  %{type: :identifier, name: n}, _r -> {:ref, n}
  %{type: :unary_expression, operator: "-", argument: %{value: v}}, _r -> -v
  %{type: :call_expression} = node, _r ->
    callee = get_in(node, [:callee, :property, :name]) || "unknown"
    {:call, callee, Enum.map(node.arguments, &Map.get(&1, :value, "?"))}
  %{type: t}, _r -> {:ast, t}
  nil, _r -> nil
end

# Usage — Y-combinator needed because anonymous fns cannot self-reference
value = extract.(config_node, extract)
```

#### Find a Specific Method in a Class

```elixir
{:ok, ast} = OXC.parse(source, "file.ts")
export = Enum.find(ast.body, &(&1.type == :export_default_declaration))
methods = Enum.filter(export.declaration.body.body, &(&1.type == :method_definition))
target = Enum.find(methods, &(&1.key.name == "describe"))
```

#### Find Property in ObjectExpression

```elixir
# Object property keys can be identifiers (.name) or literals (.value) — check both
find_prop = fn props, name ->
  Enum.find(props, fn p ->
    (Map.get(p.key, :name) || Map.get(p.key, :value)) == name
  end)
end

prop = find_prop.(object_node.properties, "id")
```

#### Analyze Class Hierarchy Across Files

```elixir
files = Path.wildcard("src/**/*.ts")

classes = Enum.map(files, fn path ->
  source = File.read!(path)
  case OXC.parse(source, Path.basename(path)) do
    {:ok, ast} ->
      export = Enum.find(ast.body, &(&1.type == :export_default_declaration))
      if export && export.declaration && export.declaration.body do
        class = export.declaration
        methods = Enum.filter(class.body.body, &(&1.type == :method_definition))
        %{
          name: class.id && class.id.name,
          super: class.superClass && class.superClass.name,
          methods: Enum.map(methods, & &1.key.name),
          path: path
        }
      end
    _ -> nil
  end
end)
|> Enum.reject(&is_nil/1)
```

### Error Handling (0.7+)

```elixir
# Soft-fail variant — always returns {:ok, _} | {:error, [%{message: String.t()}]}
case OXC.parse(source, "file.ts") do
  {:ok, ast} -> process(ast)
  {:error, errors} ->
    for %{message: msg} <- errors, do: Logger.warning("OXC: #{msg}")
end

# Bang variant raises OXC.Error (was RuntimeError in 0.6)
try do
  OXC.parse!(source, "file.ts")
rescue
  e in OXC.Error -> Logger.error(Exception.message(e))
end
```

### Migrating from 0.6.x to 0.7.x

1. Replace string-valued `:type`/`:kind` pattern matches with snake_case atoms:
   - `%{type: "ClassDeclaration"}` → `%{type: :class_declaration}`
   - `node.type == "Identifier"` → `node.type == :identifier`
2. Replace `rescue RuntimeError` on bang functions with `rescue OXC.Error`.
3. Error-tuple destructuring: `{:error, msg}` → `{:error, [%{message: msg} | _]}`.
4. Consider switching ad-hoc import rewrites to `OXC.rewrite_specifiers/3`.
5. Consider replacing `OXC.imports/2` with `OXC.collect_imports/2` when you need type info or byte offsets.

### Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| `FunctionClauseError` after upgrade | Code still matching string types | Swap `"ClassDeclaration"` → `:class_declaration` etc. |
| `KeyError` on AST node | Not all nodes have expected fields | Pattern match on `.type` first, use `Map.get/3` for optional fields |
| `.superClass` is nil | Class has no `extends` | Check `is_nil(class.superClass)` before accessing `.name` |
| Property key access fails | Keys can be identifier (`.name`) or literal (`.value`) | Check both: `p.key.name \|\| p.key.value` |
| Wrong file extension | OXC uses extension to pick parser | `.ts` for TypeScript, `.tsx` for JSX+TS, `.js`/`.jsx` for JS |
| Y-combinator forgotten | Anonymous fns cannot self-recurse | Pass `fn` as arg: `extract.(node, extract)` |
| `:export_default_declaration` not found | File may not have `export default` | Check for `:class_declaration` directly as fallback |
| `bundle/2` returns empty | Missing `:entry` option | Required since 0.6.0 — pass `entry: "main.ts"` |

### DO NOT

1. **Don't use string keys** — OXC returns atom-keyed maps. `node.type` not `node["type"]`.
2. **Don't match string type values in 0.7+** — AST `:type`/`:kind` values are atoms (`:import_declaration`, not `"ImportDeclaration"`).
3. **Don't assume node shapes** — Always pattern match on `.type` first.
4. **Don't parse just to validate** — Use `OXC.valid?/2`; it skips AST allocation.
5. **Don't parse just to get imports** — Use `OXC.imports/2` for source strings, `OXC.collect_imports/2` when you need type info / offsets.
6. **Don't hand-roll import rewrites** — `OXC.rewrite_specifiers/3` is a single pass.
7. **Don't use OXC to run JS** — OXC is static analysis only. Use QuickBEAM for runtime execution.

### Performance

| Operation | Approximate Time |
|-----------|-----------------|
| Parse 14.5k-line TS file | ~43ms |
| Transform TS to JS | ~10ms |
| Minify | ~5ms |
| `valid?` check | ~20ms |
| `imports` extraction | ~15ms |
| `collect_imports` | ~20ms |

OXC is a Rust NIF — CPU-bound on the scheduler. For batch processing many files, use `Task.async_stream` with controlled concurrency.
