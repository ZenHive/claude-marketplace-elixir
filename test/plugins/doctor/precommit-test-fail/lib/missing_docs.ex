# Module with missing documentation to trigger mix doctor failure
defmodule MissingDocs do
  # No @moduledoc

  # No @doc
  def public_function do
    :ok
  end

  # No @doc
  def another_public_function(arg) do
    arg
  end
end
