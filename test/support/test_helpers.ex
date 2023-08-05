defmodule Flop.Phoenix.TestHelpers do
  @moduledoc """
  Defines opts provider functions reference in the config for tests.
  """

  use Phoenix.Component

  import ExUnit.Assertions
  import MyAppWeb.CoreComponents
  import Phoenix.LiveViewTest

  alias Plug.Conn.Query

  def render_form(assigns) do
    (&filter_form/1)
    |> render_component(assigns)
    |> Floki.parse_fragment!()
  end

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
