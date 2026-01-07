defmodule TestPhoenixComponents do
  @moduledoc """
  Test file for private function documentation hook with Phoenix components.

  Expected failures (3 functions):
  - Line ~13: missing_doc_false - Has comment but no @doc false
  - Line ~18: missing_comment - Has @doc false but no explanatory comment
  - Line ~23: subtract - One-liner missing @doc false

  The first 3 defp functions should trigger warnings.
  All functions after the marker comment should PASS.
  """

  use Phoenix.Component

  # FAIL: Has comment but no @doc false
  defp missing_doc_false(x) do
    x + 1
  end

  @doc false
  defp missing_comment(x) do
    x * 2
  end

  defp subtract(a, b), do: a - b

  # ========== ALL FUNCTIONS BELOW SHOULD PASS ==========

  # Phoenix component with attrs
  @doc false
  # Renders a toolbar with search and filters
  attr :search, :string, required: true
  attr :verified_filter, :string, default: nil
  attr :search_debounce_ms, :integer, default: 300

  defp toolbar(assigns) do
    ~H"""
    <div>Toolbar</div>
    """
  end

  # Phoenix component with slot
  @doc false
  # Modal dialog component
  attr :id, :string, required: true
  slot :inner_block, required: true

  defp modal(assigns) do
    ~H"""
    <div>Modal</div>
    """
  end

  # Phoenix component with many attrs
  @doc false
  # Complex form input with validation
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :type, :string, default: "text"
  attr :class, :string, default: nil
  attr :errors, :list, default: []
  attr :rest, :global

  defp input(assigns) do
    ~H"""
    <input />
    """
  end

  # Regular defp without attrs, with docs
  @doc false
  # Calculates pagination offset
  defp calculate_offset(page, per_page) do
    (page - 1) * per_page
  end

  # Trivial one-liner, only needs @doc false
  @doc false
  defp add(a, b), do: a + b

  # Component with blank lines between doc and attrs
  @doc false
  # Card component

  attr :title, :string, required: true

  defp card(assigns) do
    ~H"""
    <div>Card</div>
    """
  end
end
