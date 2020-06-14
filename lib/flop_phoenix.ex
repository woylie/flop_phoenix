defmodule FlopPhoenix do
  @moduledoc """
  View helper functions for Phoenix and Flop.
  """

  use Phoenix.HTML

  @wrapper_class "pagination"

  @spec pagination(Flop.Meta.t(), function, [any], keyword) ::
          Phoenix.HTML.safe()
  def pagination(
        %Flop.Meta{} = meta,
        route_helper,
        route_helper_args,
        opts \\ []
      ) do
    opts = Keyword.put_new(opts, :wrapper_class, @wrapper_class)

    _page_link_helper =
      build_page_link_helper(meta, route_helper, route_helper_args)

    content_tag :nav,
      class: opts[:wrapper_class],
      role: "navigation",
      aria: [label: "pagination"] do
      []
    end
  end

  defp build_page_link_helper(meta, route_helper, route_helper_args) do
    fn page ->
      apply(
        route_helper,
        route_helper_args ++ [[page: page, page_size: meta.page_size]]
      )
    end
  end
end
