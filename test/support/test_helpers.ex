defmodule Flop.Phoenix.TestHelpers do
  @moduledoc """
  Defines opts provider functions reference in the config for tests.
  """

  use Phoenix.Component

  import MyAppWeb.CoreComponents
  import Phoenix.HTML
  import Phoenix.HTML.Form
  import Phoenix.LiveViewTest

  def form_to_html(meta, opts \\ [], function) do
    meta
    |> form_for("/", opts, function)
    |> safe_to_string()
    |> Floki.parse_fragment!()
  end

  def parse_heex(heex) do
    heex
    |> rendered_to_string()
    |> Floki.parse_fragment!()
  end

  def render_form(assigns) do
    rest = assigns_to_attributes(assigns, [:meta, :fields])
    assigns = Map.put(assigns, :rest, rest)
    parse_heex(~H"<.filter_form meta={@meta} fields={@fields} {@rest} />")
  end
end
