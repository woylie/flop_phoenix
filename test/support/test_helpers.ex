defmodule Flop.Phoenix.TestHelpers do
  @moduledoc """
  Defines opts provider functions reference in the config for tests.
  """

  use Phoenix.Component

  import MyAppWeb.CoreComponents
  import Phoenix.LiveViewTest

  def render_form(assigns) do
    (&filter_form/1)
    |> render_component(assigns)
    |> Floki.parse_fragment!()
  end
end
