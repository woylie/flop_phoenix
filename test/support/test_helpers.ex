defmodule Flop.Phoenix.TestHelpers do
  @moduledoc """
  Defines opts provider functions reference in the config for tests.
  """

  use Phoenix.Component

  import ExUnit.Assertions
  import MyAppWeb.CoreComponents
  import Phoenix.LiveViewTest

  alias Plug.Conn.Query

  @doc """
  Renders the given HEEx template and parses it with Floki.

  ## Example

      parse_heex(~H"<p>Hello!</p>")
  """
  def parse_heex(heex) do
    heex
    |> rendered_to_string()
    |> Floki.parse_fragment!()
  end

  @doc """
  Returns the trimmed text nodes from the first level of the HTML tree.
  """
  def text(html) do
    html
    |> Floki.text(deep: false)
    |> String.trim()
  end

  @doc """
  Returns the trimmed text nodes from the first level of the HTML tree returned
  by the selector.

  Raises if the selector returns zero or more than one result.
  """
  def text(html, selector) do
    html
    |> find_one(selector)
    |> Floki.text(deep: false)
    |> String.trim()
  end

  @doc """
  Wrapper around `Floki.attribute/2` that unwraps the single attribute.

  Raises if the attribute occurs multiple times.
  """
  def attribute(html, name) do
    case Floki.attribute(html, name) do
      [value] -> value
      [] -> nil
      _ -> raise "found attribute #{name} multiple times"
    end
  end

  @doc """
  Wrapper around `Floki.attribute/3` that unwraps the single attribute.

  Raises if the attribute occurs multiple times.
  """
  def attribute(html, selector, name) do
    html
    |> find_one(selector)
    |> attribute(name)
  end

  def find_one(html, selector) do
    case Floki.find(html, selector) do
      [inner_html] ->
        inner_html

      [] ->
        raise """
        Selector #{inspect(selector)} did not return any results in:

        #{inspect(html, pretty: true)}
        """

      [_ | _] = results ->
        raise """
        Selector #{inspect(selector)} returned multiple results:

        #{inspect(results, pretty: true)}
        """
    end
  end

  def render_form(assigns) do
    (&filter_form/1)
    |> render_component(assigns)
    |> Floki.parse_fragment!()
  end

  @doc """
  Asserts that two URLs given as strings match.

  Decodes the query parameters before comparing them to account for different
  parameter orders.

  ## Example

      iex> url_a = "/pets?page=2&page_size=10"
      iex> url_b = "/pets?page_size=10&page=2"
      iex> assert_urls_match(url_a, url_b)
      true
  """
  def assert_urls_match(url_a, url_b)
      when is_binary(url_a) and is_binary(url_b) do
    uri_a = URI.parse(url_a)
    uri_b = URI.parse(url_b)
    query_a = Query.decode(uri_a.query)
    query_b = Query.decode(uri_b.query)

    assert uri_a.path == uri_b.path
    assert query_a == query_b
  end

  @doc """
  Asserts that two URLs match.

  The first path is be given as a string. The second path is given as a
  path and a keyword list of query parameters.

  Decodes the query parameters before comparing them to account for different
  parameter orders.

  ## Example

      iex> url = "/pets?page=2&page_size=10"
      iex> query = [page_size: 10, page: 2]
      iex> assert_urls_match(url, "/pets", query)
      true
  """
  def assert_urls_match(url, path, query)
      when is_binary(url) and is_binary(path) and is_list(query) do
    uri = URI.parse(url)
    query_a = Query.decode(uri.query)
    query_b = query |> Query.encode() |> Query.decode()

    assert uri.path == path
    assert query_a == query_b
  end
end
