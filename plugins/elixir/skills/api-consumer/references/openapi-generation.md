# Part 3: OpenAPI Enhancement (Optional)

**Rule: When API provides OpenAPI spec, generate code from it.**

This is an alternative approach when you have access to an OpenAPI specification.

## When to use OpenAPI generation

**Use OpenAPI generation when:**
- API provides official OpenAPI/Swagger spec
- Spec is actively maintained and accurate
- You want auto-generated type specs
- API has many endpoints (50+)

**Use declarative macros when:**
- No OpenAPI spec available
- Spec is outdated or incomplete
- You need precise control over function signatures
- API has moderate endpoints (10-50)

## OpenAPI generation mix task

```elixir
defmodule Mix.Tasks.Api.GenerateFromSpec do
  @moduledoc """
  Generate API client from OpenAPI specification.

  ## Usage

      mix api.generate_from_spec --url https://api.example.com/openapi.yaml
      mix api.generate_from_spec --file priv/openapi.json

  """
  use Mix.Task

  @shortdoc "Generate API client from OpenAPI spec"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [url: :string, file: :string])

    spec =
      cond do
        opts[:url] -> fetch_spec(opts[:url])
        opts[:file] -> read_spec(opts[:file])
        true -> raise "Must provide --url or --file"
      end

    endpoints = parse_openapi(spec)
    content = generate_module(endpoints)

    File.write!("lib/my_app/api/generated_endpoints.ex", content)
    Mix.shell().info("Generated #{length(endpoints)} endpoints")
  end

  defp fetch_spec(url) do
    {:ok, %{body: body}} = Req.get(url)
    parse_yaml_or_json(body)
  end

  defp read_spec(path) do
    path |> File.read!() |> parse_yaml_or_json()
  end

  defp parse_openapi(spec) do
    spec["paths"]
    |> Enum.flat_map(fn {path, methods} ->
      Enum.map(methods, fn {method, details} ->
        %{
          operation: derive_operation_name(details["operationId"], method, path),
          method: String.to_atom(method),
          path: path,
          requires_auth: details["security"] != nil,
          params: extract_params(details["parameters"] || []),
          response_type: extract_response_type(details["responses"], spec),
          doc: details["summary"] || details["description"] || ""
        }
      end)
    end)
  end

  defp derive_operation_name(nil, method, path) do
    path
    |> String.replace(~r/[{}]/, "")
    |> String.split("/")
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("_")
    |> then(&"#{method}_#{&1}")
    |> String.to_atom()
  end

  defp derive_operation_name(operation_id, _, _), do: String.to_atom(operation_id)

  defp extract_params(params) do
    Enum.map(params, fn param ->
      %{
        name: String.to_atom(param["name"]),
        in: param["in"],
        required: param["required"] || false,
        type: schema_to_type(param["schema"])
      }
    end)
  end

  defp extract_response_type(responses, spec) do
    case responses["200"]["content"]["application/json"]["schema"] do
      %{"$ref" => ref} -> resolve_ref(ref, spec)
      schema -> schema_to_type(schema)
    end
  end

  defp schema_to_type(%{"type" => "string"}), do: "String.t()"
  defp schema_to_type(%{"type" => "integer"}), do: "integer()"
  defp schema_to_type(%{"type" => "number"}), do: "float()"
  defp schema_to_type(%{"type" => "boolean"}), do: "boolean()"
  defp schema_to_type(%{"type" => "array", "items" => items}), do: "list(#{schema_to_type(items)})"
  defp schema_to_type(%{"type" => "object"}), do: "map()"
  defp schema_to_type(_), do: "term()"

  defp generate_module(endpoints) do
    """
    # Auto-generated from OpenAPI spec
    # Do not edit manually - regenerate with: mix api.generate_from_spec

    [
    #{Enum.map_join(endpoints, ",\n", &endpoint_to_map/1)}
    ]
    """
  end

  defp endpoint_to_map(endpoint) do
    """
      %{
        operation: #{inspect(endpoint.operation)},
        method: #{inspect(endpoint.method)},
        path: #{inspect(endpoint.path)},
        requires_auth: #{endpoint.requires_auth},
        doc: #{inspect(endpoint.doc)}
      }
    """
  end
end
```

## Loading generated endpoints

```elixir
defmodule MyApp.API.EndpointLoader do
  @moduledoc """
  Load generated endpoints at compile time.
  """

  defmacro load_endpoints(filename) do
    quote do
      @external_resource Path.join([__DIR__, unquote(filename)])

      @generated_endpoints (
        path = Path.join([__DIR__, unquote(filename)])

        case File.read(path) do
          {:ok, content} ->
            {result, _} = Code.eval_string(content)
            result

          {:error, _} ->
            Mix.shell().info("Warning: #{path} not found, using empty endpoints")
            []
        end
      )

      def __endpoints__, do: @generated_endpoints
    end
  end
end
```
