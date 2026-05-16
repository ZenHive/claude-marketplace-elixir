defmodule IoInDoc do
  @moduledoc """
  Bad example.

      iex> result = compute()
      IO.puts(result)
  """

  @doc """
  Bad example.

      iex> r = IoInDoc.go()
      IO.inspect(r)
  """
  def go, do: 42
end
