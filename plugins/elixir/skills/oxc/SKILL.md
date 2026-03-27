---
name: oxc
description: "OXC Elixir bindings for parsing, transforming, bundling, and minifying JavaScript/TypeScript via Rust NIFs. ALWAYS use this skill when working with JS/TS source analysis, ESTree AST navigation, class hierarchy extraction, code generation from AST, TypeScript-to-JavaScript transformation, or any static analysis of JavaScript/TypeScript files. Covers parse, transform, bundle, minify, imports, walk/postwalk/collect traversal, patch_string, and the recursive value-extraction pattern. Use this even if you think you know OXC — it contains runtime-verified corrections to common misconceptions."
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/oxc.md — do not edit manually -->

## OXC: Parse, Transform, and Bundle JS/TS on the BEAM

Rust NIF bindings for the [OXC](https://oxc.rs) JavaScript toolchain. Parses, transforms, minifies, and bundles JavaScript and TypeScript entirely on the BEAM — no Node.js required.

### Scope

WHAT THIS COVERS:
  - Parsing JS/TS to ESTree AST and navigating the result
  - AST traversal (walk, postwalk, collect) and value extraction
  - Transforming TypeScript to JavaScript
  - Bundling multiple modules into a single IIFE
  - Minifying JS for production
  - Extracting import sources without a full parse
  - Source patching via byte offsets

WHAT THIS DOES NOT COVER:
  - Running JS code at runtime (use QuickBEAM)
  - Installing npm packages (use npm_ex: `mix npm.install`)
  - Frontend build pipelines with HMR (use Volt)

### API Reference

#### Parsing

```elixir
# Parse JS or TS to ESTree AST (maps with atom keys)
# File extension determines language: .ts, .tsx, .js, .jsx
{:ok, ast} = OXC.parse(source, "file.ts")
{:error, errors} = OXC.parse(bad_source, "file.ts")

# Raising variant
ast = OXC.parse!(source, "file.ts")

# Fast syntax validation (no AST allocation)
true = OXC.valid?(source, "file.ts")
```

The AST is a map with **atom keys** following the ESTree spec. Top-level has `.body` list of statement nodes. Each node has a `.type` string field.

#### Transform (TS to JS)

```elixir
# Strip type annotations AND interfaces, transform JSX
{:ok, js} = OXC.transform(source, "file.ts")
# "const x: number = 1; interface Foo { bar: string }" → "const x = 1;\n"

# Options
{:ok, js} = OXC.transform(source, "file.tsx",
  jsx: :automatic,          # :automatic | :classic
  jsx_factory: "h",         # custom JSX factory (classic mode)
  jsx_fragment: "Fragment",  # custom fragment
  import_source: "preact",  # JSX import source (automatic mode)
  target: "es2020",         # target ES version
  sourcemap: true           # generate source map
)
```

#### Minify

```elixir
# Dead code elimination, constant folding, whitespace removal
{:ok, minified} = OXC.minify(source, "file.js")
# "function add(longNameA, longNameB) { return longNameA + longNameB }"
# → "function add(e,t){return e+t}"

# Disable identifier mangling (keeps original names)
{:ok, minified} = OXC.minify(source, "file.js", mangle: false)
```

#### Bundle

```elixir
# Bundle multiple TS/JS modules into a single IIFE
# Takes [{filename, source}] tuples — imports resolved by relative path
{:ok, js} = OXC.bundle([
  {"event.ts", event_source},
  {"target.ts", target_source}  # can import from './event'
])

# Options
{:ok, js} = OXC.bundle(files,
  minify: true,
  banner: "/* v1.0 */",
  footer: "/* end */",
  define: %{"process.env.NODE_ENV" => ~s("production")},
  sourcemap: true,             # returns %{code: ..., sourcemap: ...} instead of string
  drop_console: true,
  jsx: :automatic,
  target: "es2020"
)
```

#### Imports

```elixir
# Extract import source strings (NOT specifier names) — faster than parse + collect
# Type-only imports are excluded
{:ok, sources} = OXC.imports(source, "file.ts")
# "import { ref } from 'vue'; import type { Ref } from 'vue'; import axios from 'axios'"
# → ["vue", "axios"]  (type-only 'vue' import skipped)
```

#### Patch String

```elixir
# Apply byte-offset patches to source code
patched = OXC.patch_string(source, [
  %{start: 10, end: 20, change: "replacement"},
  %{start: 30, end: 35, change: ""}  # deletion
])
```

Use `.start` and `.end` fields from AST nodes directly — they are byte offsets. Patches can be in any order; the function sorts internally.

### AST Navigation

The AST uses **atom keys**. Access with dot notation or pattern matching:

```elixir
{:ok, ast} = OXC.parse(source, "file.ts")

# Top-level: ast.body is a list of statements
# If file has `export default class`, the top-level is ExportDefaultDeclaration:
export = Enum.find(ast.body, &(&1.type == "ExportDefaultDeclaration"))
class = export.declaration

# If file has a plain class (no export default), it's ClassDeclaration directly:
class = Enum.find(ast.body, &(&1.type == "ClassDeclaration"))

# Class structure
class.id.name                    # class name (nil if anonymous)
class.superClass.name            # parent class name (nil if no extends)
class.body.body                  # list of class members

# Methods
methods = Enum.filter(class.body.body, &(&1.type == "MethodDefinition"))
method.key.name                  # method name
method.value.async               # boolean
method.value.params              # parameter list
method.value.body.body           # list of statements in method body

# FunctionExpression keys (method.value):
# :async, :id, :params, :body, :generator, :declare,
# :typeParameters, :expression, :returnType
```

#### Key ESTree Node Types

| Node Type | Key Fields | Description |
|-----------|------------|-------------|
| `ExportDefaultDeclaration` | `.declaration` | Default export (class, function) |
| `ClassDeclaration` | `.id.name`, `.superClass`, `.body.body` | Class definition |
| `MethodDefinition` | `.key.name`, `.value` (FunctionExpression) | Class method |
| `FunctionExpression` | `.async`, `.params`, `.body.body`, `.returnType` | Function value |
| `ObjectExpression` | `.properties` | Object literal `{ ... }` |
| `ArrayExpression` | `.elements` | Array literal `[ ... ]` |
| `Literal` | `.value` | String, number, boolean, null |
| `Identifier` | `.name` | Variable/reference name |
| `CallExpression` | `.callee`, `.arguments` | Function call |
| `UnaryExpression` | `.operator`, `.argument` | `-x`, `!x`, `typeof x` |
| `MemberExpression` | `.object`, `.property` | `a.b` or `a[b]` |
| `ReturnStatement` | `.argument` | `return expr` |
| `ImportDeclaration` | `.source.value`, `.specifiers` | `import ... from '...'` |

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
  %{type: "CallExpression", callee: c} -> IO.inspect(c)
  _ -> :ok
end)
```

#### postwalk — Depth-First Post-Order

```elixir
# Transform nodes bottom-up (children visited before parents)
transformed = OXC.postwalk(ast, fn
  %{type: "Identifier", name: "old"} = node -> %{node | name: "new"}
  node -> node
end)

# With accumulator — collect data during traversal
{_ast, patches} = OXC.postwalk(ast, [], fn
  %{type: "ImportDeclaration", source: %{value: "vue"} = src} = node, acc ->
    {node, [%{start: src.start, end: src.end, change: "'/@vendor/vue.js'"} | acc]}
  node, acc ->
    {node, acc}
end)
patched = OXC.patch_string(source, patches)
```

#### collect — Filter and Extract

```elixir
# Return {:keep, value} to collect, :skip to ignore
method_names = OXC.collect(ast, fn
  %{type: "MethodDefinition", key: %{name: name}} -> {:keep, name}
  _ -> :skip
end)
# => ["describe", "fetchTicker", "fetchBalance", ...]

identifiers = OXC.collect(ast, fn
  %{type: "Identifier", name: n} -> {:keep, n}
  _ -> :skip
end)
```

### Recipes

#### Recursive AST Value Extraction

Convert AST subtrees (ObjectExpression, ArrayExpression, Literal) back to Elixir values. Standard pattern for extracting configuration objects:

```elixir
extract = fn
  %{type: "Literal", value: v}, _r -> v
  %{type: "ObjectExpression", properties: props}, r ->
    Map.new(props, fn p ->
      key = Map.get(p.key, :name) || to_string(Map.get(p.key, :value, "?"))
      {key, r.(p.value, r)}
    end)
  %{type: "ArrayExpression", elements: els}, r ->
    Enum.map(els, &r.(&1, r))
  %{type: "Identifier", name: "undefined"}, _r -> :undefined
  %{type: "Identifier", name: n}, _r -> {:ref, n}
  %{type: "UnaryExpression", operator: "-", argument: %{value: v}}, _r -> -v
  %{type: "CallExpression"} = node, _r ->
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
export = Enum.find(ast.body, &(&1.type == "ExportDefaultDeclaration"))
methods = Enum.filter(export.declaration.body.body, &(&1.type == "MethodDefinition"))
target = Enum.find(methods, &(&1.key.name == "describe"))
```

#### Find Property in ObjectExpression

```elixir
# Object property keys can be Identifiers (.name) or Literals (.value) — check both
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
      export = Enum.find(ast.body, &(&1.type == "ExportDefaultDeclaration"))
      if export && export.declaration && export.declaration.body do
        class = export.declaration
        methods = Enum.filter(class.body.body, &(&1.type == "MethodDefinition"))
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

### Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| `KeyError` on AST node | Not all nodes have expected fields | Pattern match on `.type` first, use `Map.get/3` for optional fields |
| `.superClass` is nil | Class has no `extends` | Check `is_nil(class.superClass)` before accessing `.name` |
| Property key access fails | Keys can be Identifier (`.name`) or Literal (`.value`) | Check both: `p.key.name \|\| p.key.value` |
| Wrong file extension | OXC uses extension to pick parser | `.ts` for TypeScript, `.tsx` for JSX+TS, `.js`/`.jsx` for JS |
| Y-combinator forgotten | Anonymous fns cannot self-recurse | Pass `fn` as arg: `extract.(node, extract)` |
| `ExportDefaultDeclaration` not found | File may not have `export default` | Check for `ClassDeclaration` directly as fallback |

### DO NOT

1. **Don't use string keys** — OXC returns atom-keyed maps. `node.type` not `node["type"]`.
2. **Don't assume node shapes** — Always pattern match on `.type` first.
3. **Don't parse just to validate** — Use `OXC.valid?/2`; it skips AST allocation.
4. **Don't parse just to get imports** — Use `OXC.imports/2`; it returns source strings faster.
5. **Don't use OXC to run JS** — OXC is static analysis only. Use QuickBEAM for runtime execution.

### Performance

| Operation | Approximate Time |
|-----------|-----------------|
| Parse 14.5k-line TS file | ~43ms |
| Transform TS to JS | ~10ms |
| Minify | ~5ms |
| `valid?` check | ~20ms |
| `imports` extraction | ~15ms |

OXC is a Rust NIF — CPU-bound on the scheduler. For batch processing many files, use `Task.async_stream` with controlled concurrency.
