# Elixir Macro Patterns Reference

Comprehensive patterns for Elixir metaprogramming — from basics to advanced compile-time code generation.

## The AST: Everything is a Three-Element Tuple

Elixir code compiles to an AST of `{function, metadata, arguments}` tuples. Five literals return themselves when quoted: atoms, strings, numbers, lists, and 2-element tuples.

```elixir
quote do: 1 + 2
#=> {:+, [context: Elixir, import: Kernel], [1, 2]}

quote do: %{key: "value"}
#=> {:%{}, [], [key: "value"]}
```

Understanding the AST is essential — macros receive AST and must return AST.

## quote/unquote Patterns

### Basic Injection

`unquote/1` injects evaluated values into quoted expressions:

```elixir
name = :hello
quote do
  def unquote(name)(), do: "world"
end
#=> {:def, [], [{:hello, [], []}, [do: "world"]]}
```

### unquote_splicing for Lists

Inject list elements individually (not as a single list argument):

```elixir
args = [:a, :b, :c]
quote do
  def my_func(unquote_splicing(args)), do: :ok
end
# Generates: def my_func(a, b, c), do: :ok
```

### bind_quoted: Preventing Re-evaluation

Without `bind_quoted`, each `unquote(expr)` evaluates the expression again:

```elixir
# BAD: expr evaluated twice (side effects run twice)
defmacro log_twice(expr) do
  quote do
    IO.puts(unquote(expr))
    IO.puts(unquote(expr))
  end
end

# GOOD: expr evaluated once, bound to variable
defmacro log_twice(expr) do
  quote bind_quoted: [expr: expr] do
    IO.puts(expr)
    IO.puts(expr)
  end
end
```

**Rule**: Always use `bind_quoted` unless there's a specific reason not to (e.g., generating function heads where `unquote` is needed in pattern position).

### Macro.escape/1 for Complex Data

Embed complex data structures (maps, structs) in quoted code:

```elixir
config = %{timeout: 5000, retries: 3}
quote do
  def config, do: unquote(Macro.escape(config))
end
```

Without `Macro.escape/1`, maps and structs fail inside `quote` blocks.

## defmacro Patterns

### Basic Macro

```elixir
defmodule MyMacros do
  defmacro unless(condition, do: block) do
    quote do
      if !unquote(condition), do: unquote(block)
    end
  end
end
```

### defmacrop (Private Macros)

Module-internal macros — cannot be imported:

```elixir
defmacrop debug(expr) do
  quote bind_quoted: [expr: expr] do
    IO.inspect(expr, label: "DEBUG")
  end
end
```

Use for helper macros that build parts of other macros.

## Macro Hygiene

### Default: Hygienic

Variables inside `quote` don't leak into the caller's scope:

```elixir
defmacro hygienic do
  quote do
    val = -1  # This val is isolated
  end
end

val = 42
hygienic()
val  #=> still 42
```

### Breaking Hygiene with var!/2

When a macro intentionally needs to set variables in the caller's scope:

```elixir
defmacro setup_conn do
  quote do
    var!(conn) = %Plug.Conn{}
  end
end
```

**Use sparingly** — breaking hygiene makes macros harder to reason about. Prefer returning values over setting variables.

## The __using__/1 Pattern

The standard entry point when a module does `use MyLibrary`:

```elixir
defmodule MyDSL do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import MyDSL, only: [api_method: 4]
      @before_compile MyDSL
      Module.register_attribute(__MODULE__, :api_methods, accumulate: true)
      @api_opts opts
    end
  end
end
```

This pattern:
1. Imports the macro functions consumers will call
2. Registers `@before_compile` to generate code after all attributes are accumulated
3. Sets up accumulating module attributes
4. Stores options for later use

### Real-World: Phoenix Router

```elixir
# Simplified Phoenix pattern
defmacro __using__(_opts) do
  quote do
    import Phoenix.Router
    Module.register_attribute(__MODULE__, :routes, accumulate: true)
    @before_compile Phoenix.Router
  end
end

defmacro get(path, controller, action) do
  quote do
    @routes {:get, unquote(path), unquote(controller), unquote(action)}
  end
end
```

## Module Attribute Accumulation + @before_compile

The most powerful pattern for DSLs — accumulate declarations, then generate code at compile time.

### Full Pattern

```elixir
defmodule APIDsl do
  defmacro __using__(_opts) do
    quote do
      import APIDsl
      Module.register_attribute(__MODULE__, :endpoints, accumulate: true)
      @before_compile APIDsl
    end
  end

  defmacro endpoint(name, method, path) do
    quote do
      @endpoints {unquote(name), unquote(method), unquote(path)}
    end
  end

  defmacro __before_compile__(env) do
    endpoints = Module.get_attribute(env.module, :endpoints)

    for {name, method, path} <- endpoints do
      quote do
        @doc "Calls #{unquote(method) |> to_string() |> String.upcase()} #{unquote(path)}"
        def unquote(name)() do
          request(unquote(method), unquote(path))
        end
      end
    end
  end
end

# Usage:
defmodule MyAPI do
  use APIDsl

  endpoint :get_users, :get, "/users"
  endpoint :get_user, :get, "/users/:id"
  endpoint :create_user, :post, "/users"
end
```

### Real-World: Ecto Schema

```elixir
# Simplified Ecto pattern
defmacro schema(source, do: block) do
  quote do
    Module.register_attribute(__MODULE__, :fields, accumulate: true)
    unquote(block)
    # After block executes, @fields contains all field declarations
  end
end

defmacro field(name, type, opts \\ []) do
  quote do
    @fields {unquote(name), unquote(type), unquote(opts)}
  end
end
```

## Dynamic Arities with Macro.generate_arguments/2

Generate function arguments for macros that produce functions with variable parameter counts:

```elixir
defmacro define_endpoint(name, path_params, body_params \\ []) do
  all_params = path_params ++ body_params
  args = Macro.generate_arguments(length(all_params), __MODULE__)

  quote do
    @spec unquote(name)(unquote_splicing(
      Enum.map(all_params, fn _ -> quote do: term() end)
    )) :: {:ok, map()} | {:error, term()}
    def unquote(name)(unquote_splicing(args)) do
      params = Enum.zip(unquote(all_params), [unquote_splicing(args)])
      request(params)
    end
  end
end

# Generates:
# def get_user(arg1), do: ...        (1 path param)
# def create_order(arg1, arg2), do: ... (2 params)
```

## Compile-Time Validation

Macros can validate at compile time, catching errors before runtime:

```elixir
defmacro endpoint(name, method, path) do
  unless method in [:get, :post, :put, :patch, :delete] do
    raise CompileError,
      description: "Invalid HTTP method: #{inspect(method)}. " <>
                   "Must be one of: :get, :post, :put, :patch, :delete"
  end

  quote do
    @endpoints {unquote(name), unquote(method), unquote(path)}
  end
end
```

### Validating in @before_compile

```elixir
defmacro __before_compile__(env) do
  endpoints = Module.get_attribute(env.module, :endpoints)

  # Check for duplicate names
  names = Enum.map(endpoints, &elem(&1, 0))
  dupes = names -- Enum.uniq(names)
  unless dupes == [] do
    raise CompileError,
      description: "Duplicate endpoint names: #{inspect(dupes)}"
  end

  # Generate code...
end
```

## Debugging Macros

### Macro.expand_once/2 and Macro.expand/2

Inspect what a macro generates:

```elixir
# In IEx or tests:
ast = quote do: MyDSL.endpoint(:get_users, :get, "/users")

ast
|> Macro.expand_once(__ENV__)
|> Macro.to_string()
|> IO.puts()
```

- `expand_once/2` — One level of expansion
- `expand/2` — Full recursive expansion

### IO.inspect in Macros

```elixir
defmacro my_macro(expr) do
  IO.inspect(expr, label: "macro input AST")
  result = quote do: unquote(expr) + 1
  IO.inspect(result, label: "macro output AST")
  result
end
```

The `IO.inspect` calls run at **compile time**, showing the AST transformation.

## Testing Macros

### Test the Generated Functions

The simplest approach — test the public API, not the macro internals:

```elixir
defmodule TestModule do
  use MyDSL
  endpoint :test_endpoint, :get, "/test"
end

test "generated function exists and works" do
  assert function_exported?(TestModule, :test_endpoint, 0)
  assert {:ok, _} = TestModule.test_endpoint()
end
```

### Test Compile-Time Validation

```elixir
test "rejects invalid HTTP method" do
  assert_raise CompileError, ~r/Invalid HTTP method/, fn ->
    defmodule Bad do
      use MyDSL
      endpoint :bad, :invalid, "/bad"
    end
  end
end
```

### Test AST Output

For complex macros, verify the generated AST directly:

```elixir
test "generates correct AST" do
  ast = quote do: MyDSL.endpoint(:get_users, :get, "/users")
  expanded = Macro.expand_once(ast, __ENV__)

  assert {:@, _, [{:endpoints, _, [{:get_users, :get, "/users"}]}]} = expanded
end
```

## Real-World Examples

### ExUnit's `test` Macro (Simplified)

```elixir
defmacro test(message, do: block) do
  fun_name = :"test #{message}"
  quote bind_quoted: [fun_name: fun_name, block: Macro.escape(block)] do
    def unquote(fun_name)(_context) do
      unquote(block)
    end
  end
end
```

### Phoenix's `plug` Macro (Simplified)

```elixir
defmacro plug(plug, opts \\ []) do
  quote do
    @plugs {unquote(plug), unquote(opts)}
  end
end
```

Plugs accumulate in `@plugs`, then `@before_compile` generates the plug pipeline.

### Absinthe's Field Macro (Simplified)

```elixir
defmacro field(name, type, do: block) do
  quote do
    @fields %{
      name: unquote(name),
      type: unquote(type),
      resolver: fn -> unquote(block) end
    }
  end
end
```

## Common Pitfalls

1. **Forgetting `Macro.escape/1`** for maps/structs in `quote` blocks
2. **Not using `bind_quoted`** causing double evaluation of side effects
3. **Over-using `var!/2`** — prefer returning values over injecting variables
4. **Debugging at runtime** when the issue is at compile time — use `Macro.expand`
5. **Not providing escape hatches** — users MUST be able to bypass the DSL
6. **Generating too much code** — compile times suffer; keep generated functions focused
7. **Macro calling macro** without understanding expansion order — `expand_once` helps
