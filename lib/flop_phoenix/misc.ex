defmodule Flop.Phoenix.Misc do
  @moduledoc false

  @doc """
  Deep merge for keyword lists.

      iex> deep_merge(
      ...>   [aria: [role: "navigation"]],
      ...>   [aria: [label: "pagination"]]
      ...> )
      [aria: [role: "navigation", label: "pagination"]]

      iex> deep_merge(
      ...>   [class: "a"],
      ...>   [class: "b"]
      ...> )
      [class: "b"]
  """
  @spec deep_merge(keyword, keyword) :: keyword
  def deep_merge(a, b) when is_list(a) and is_list(b) do
    Keyword.merge(a, b, &do_deep_merge/3)
  end

  defp do_deep_merge(_key, a, b) when is_list(a) and is_list(b) do
    deep_merge(a, b)
  end

  defp do_deep_merge(_key, _, b), do: b

  @doc """
  Puts a `value` under `key` only if the value is not `nil`.

      iex> maybe_put([], :a, "b")
      [a: "b"]

      iex> maybe_put([], :a, nil)
      []
  """
  def maybe_put(keywords, _key, nil), do: keywords
  def maybe_put(keywords, key, value), do: Keyword.put(keywords, key, value)

  @doc """
  Returns the global opts derived from a function referenced in the application
  environment.
  """
  @spec get_global_opts(atom) :: keyword
  def get_global_opts(component) when component in [:pagination, :table] do
    case opts_func(component) do
      nil -> []
      {module, func} -> apply(module, func, [])
    end
  end

  defp opts_func(component) do
    :flop_phoenix
    |> Application.get_env(component, [])
    |> Keyword.get(:opts)
  end
end
