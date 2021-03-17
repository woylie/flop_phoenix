defmodule Flop.Phoenix.Live.PaginationComponent do
  @moduledoc """
  LiveView component for pagination.

  This component takes the same configuration as `Flop.Phoenix.pagination/4`. It
  uses `Phoenix.LiveView.Helpers.live_patch/2` to display the pagination links,
  so you will have to handle the pagination parameters in the `handle_params/3`
  callback function of your LiveView.

  ## Example

      defmodule MyAppWeb.PetLive.Index do
        use MyAppWeb, :live_view

        alias MyApp.Pets

        @impl Phoenix.LiveView
        def mount(_params, _session, socket) do
          {:ok, socket)}
        end

        @impl Phoenix.LiveView
        def handle_params(params, _, socket) do
          with {:ok, {pets, meta}} = Pets.list_pets(params) do
            {noreply, assign(socket, %{pets: pets, meta: meta})}

          {:error, reason} ->
            # handle error
            {noreply, socket}

          end
        end
      end
  """
  use Phoenix.HTML
  use Phoenix.LiveComponent

  alias Flop.Meta
  alias Flop.Phoenix.Pagination

  def render(
        %{
          meta: %Meta{} = meta,
          route_helper: route_helper,
          route_helper_args: route_helper_args,
          opts: opts
        } = assigns
      ) do
    opts = opts |> Pagination.init_opts() |> Keyword.put(:live_view, true)
    attrs = Pagination.build_attrs(opts)

    page_link_helper =
      Pagination.build_page_link_helper(meta, route_helper, route_helper_args)

    ~L"""
    <%= if @meta.total_pages > 1 do %>
      <%= content_tag :nav, attrs do %>
        <%= Pagination.previous_link(meta, page_link_helper, opts) %>
        <%= Pagination.next_link(meta, page_link_helper, opts) %>
        <%= Pagination.page_links(meta, page_link_helper, opts) %>
      <% end %>
    <% end %>
    """
  end
end
