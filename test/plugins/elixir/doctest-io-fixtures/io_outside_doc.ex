defmodule IoOutsideDoc do
  @moduledoc "Just a normal module."

  def runtime_log do
    IO.puts("this is fine — outside @doc")
    IO.inspect(%{a: 1})
  end
end
