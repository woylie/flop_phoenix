defmodule Flop.Phoenix.Misc do
  @moduledoc false

  @doc """
  Deep merge for keyword lists.
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
  """
  def maybe_put(keywords, _key, nil), do: keywords
  def maybe_put(keywords, key, value), do: Keyword.put(keywords, key, value)
end
