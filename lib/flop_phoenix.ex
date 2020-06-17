defmodule FlopPhoenix do
  @moduledoc """
  View helper functions for Phoenix and Flop.

  ## Pagination

  `Flop.meta/3` returns a `Flop.Meta` struct, which holds information such as
  the total item count, the total page count, the current page etc. This is all
  you need to render pagination links. `Flop.run/3`, `Flop.validate_and_run/3`
  and `Flop.validate_and_run!/3` all return the query results alongside the
  meta information.

  If you set up your context as described in the
  [Flop documentation](https://hexdocs.pm/flop), you will have a `list` function
  similar to the following:

      @spec list_pets(Flop.t() | map) ::
              {:ok, {[Pet.t()], Flop.Meta.t}} | {:error, Changeset.t()}
      def list_pets(flop \\\\ %{}) do
        Flop.validate_and_run(Pet, flop, for: Pet)
      end

  ### Controller

  You can call this function from your controller to get both the data and the
  meta data and pass both to your template.

      defmodule MyAppWeb.PetController do
        use MyAppWeb, :controller

        alias Flop
        alias MyApp.Pets
        alias MyApp.Pets.Pet

        action_fallback MyAppWeb.FallbackController

        def index(conn, params) do
          with {:ok, {pets, meta}} <- Pets.list_pets(params) do
            render(conn, "index.html", meta: meta, pets: pets)
          end
        end
      end

  ### View

  To make the `FlopPhoenix` functions available in all templates, locate the
  `view_helpers/0` macro in `my_app_web.ex` and add another import statement:

      defp view_helpers do
        quote do
          # ...

          import FlopPhoenix

          # ...
        end
      end

  ### Template

  In your index template, you can now add pagination links like this:

      <h1>Listing Pets</h1>

      <table>
      # ...
      </table>

      <%= pagination(@meta, &Routes.pet_path/3, [@conn, :index]) %>

  The second argument of `FlopPhoenix.pagination/4` is the route helper
  function, and the third argument is a list of arguments for that route helper.
  If you want to add path parameters, you can do that like this:

      <%= pagination(@meta, &Routes.owner_pet_path/4, [@conn, :index, @owner]) %>

  ## Customization

  `FlopPhoenix` sets some default classes and aria attributes.

      <nav aria-label="pagination" class="pagination is-centered" role="navigation">
        <span class="pagination-previous" disabled="disabled">Previous</span>
        <a class="pagination-next" href="/pets?page=2&amp;page_size=10">Next</a>
        <ul class="pagination-list">
          <li><span class="pagination-ellipsis">&hellip;</span></li>
          <li>
            <a aria-current="page"
               aria-label="Goto page 1"
               class="pagination-link is-current"
               href="/pets?page=1&amp;page_size=10">1</a>
          </li>
          <li>
            <a aria-label="Goto page 2"
               class="pagination-link"
               href="/pets?page=2&amp;page_size=10">2</a>
          </li>
          <li>
            <a aria-label="Goto page 3"
               class="pagination-link"
               href="/pets?page=3&amp;page_size=2">3</a>
          </li>
          <li><span class="pagination-ellipsis">&hellip;</span></li>
        </ul>
      </nav>

  You can customize the css classes and add additional HTML attributes. It is
  recommended to set up the customization once in a view helper module, so that
  your templates aren't cluttered with options.

  Create a new file called `views/flop_helpers.ex`:

      defmodule MyAppWeb.FlopHelpers do
        use Phoenix.HTML

        def pagination(meta, route_helper, route_helper_args) do
          opts = [
            # ...
          ]

          FlopPhoenix.pagination(meta, route_helper, route_helper_args, opts)
        end
      end

  Change the import in `my_app_web.ex`:

      defp view_helpers do
        quote do
          # ...

          import MyAppWeb.FlopHelpers

          # ...
        end
      end

  ## Page link options

  By default, page links for all pages are show. You can limit the number of
  page links or disable them altogether by passing the `:page_links` option.

  - `:all`: Show all page links (default).
  - `:hide`: Don't show any page links. Only the previous/next links will be
    shown.
  - `{:ellipsis, x}`: Show only x page links. Additional list items with
    ellipses are shown if there are more pages.

  ## Attributes and CSS classes

  You can overwrite the default attributes of the `<nav>` tag and the pagination
  links by passing these options:

  - `:wrapper_attrs`: attributes for the `<nav>` tag
  - `:previous_link_attrs`: attributes for the previous link (`<a>` if active,
    `<span>` if disabled)
  - `:next_link_attrs`: attributes for the next link (`<a>` if active,
    `<span>` if disabled)
  - `:pagination_list_attrs`: attributes for the page link list (`<ul>`)
  - `:pagination_link_attrs`: attributes for the page links (`<a>`)
  - `:ellipsis_attrs`: attributes for the ellipsis element (`<span>`)
  - `:ellipsis_content`: content for the ellipsis element (`<span>`)

  ## Pagination link aria label

  For the page links, there is the `:pagination_link_aria_label` option to set
  the aria label. Since the page number is usually part of the aria label, you
  need to pass a function that takes the page number as an integer and returns
  the label as a string. The default is `&"Goto page \#{&1}"`.

  ## Previous/next links

  By default, the previous and next links contain the texts `Previous` and
  `Next`. To change this, you can pass the `:previous_link_content` and
  `:next_link_content` options.

  ## Customization example

      def pagination(meta, route_helper, route_helper_args) do
        opts = [
          ellipsis_attrs: [class: "ellipsis"],
          ellipsis_content: "‥",
          next_link_attrs: [class: "next"],
          next_link_content: next_icon(),
          page_links: {:ellipsis, 7},
          pagination_link_aria_label: &"\#{&1}ページ目へ",
          pagination_link_attrs: [class: "page-link"],
          pagination_list_attrs: [class: "page-links"],
          previous_link_attrs: [class: "prev"],
          previous_link_content: previous_icon(),
          wrapper_attrs: [class: "paginator"]
        ]

        FlopPhoenix.pagination(meta, route_helper, route_helper_args, opts)
      end

      defp next_icon do
        content_tag :i, class: "fas fa-chevron-right" do
        end
      end

      defp previous_icon do
        content_tag :i, class: "fas fa-chevron-left" do
        end
      end
  """

  use Phoenix.HTML

  alias Flop.Meta

  @next_link_class "pagination-next"
  @previous_link_class "pagination-previous"
  @wrapper_class "pagination"

  @doc """
  Renders a pagination component.

  - `meta`: The meta information of the query as returned by the `Flop` query
    functions.
  - `route_helper`: The route helper function that builds a path to the current
    page, e.g. `&Routes.pet_path/3`.
  - `route_helper_args`: The arguments to be passed to the route helper
    function, e.g. `[@conn, :index]`. The page number and page size will be
    added as query parameters.
  - `opts`: Options to customize the pagination. See section Customization.
  """
  @spec pagination(Meta.t(), function, [any], keyword) ::
          Phoenix.HTML.safe()

  def pagination(meta, route_helper, route_helper_args, opts \\ [])

  def pagination(%Meta{total_pages: p}, _, _, _) when p <= 1, do: raw(nil)

  def pagination(%Meta{} = meta, route_helper, route_helper_args, opts) do
    opts = Keyword.put_new(opts, :page_links, :all)

    attrs =
      opts
      |> Keyword.get(:wrapper_attrs, [])
      |> Keyword.put_new(:class, @wrapper_class)
      |> Keyword.put_new(:role, "navigation")
      |> Keyword.put_new(:aria, label: "pagination")

    page_link_helper =
      build_page_link_helper(meta, route_helper, route_helper_args)

    content_tag :nav, attrs do
      [
        previous_link(meta, page_link_helper, opts),
        next_link(meta, page_link_helper, opts),
        page_links(meta, page_link_helper, opts)
      ]
    end
  end

  @spec previous_link(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  defp previous_link(%Meta{} = meta, page_link_helper, opts) do
    attrs =
      opts
      |> Keyword.get(:previous_link_attrs, [])
      |> Keyword.put_new(:class, @previous_link_class)

    content = opts[:previous_link_content] || "Previous"

    if meta.has_previous_page? do
      attrs = Keyword.put(attrs, :to, page_link_helper.(meta.previous_page))

      link attrs do
        content
      end
    else
      attrs = Keyword.put(attrs, :disabled, "disabled")

      content_tag :span, attrs do
        content
      end
    end
  end

  @spec next_link(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  defp next_link(%Meta{} = meta, page_link_helper, opts) do
    attrs =
      opts
      |> Keyword.get(:next_link_attrs, [])
      |> Keyword.put_new(:class, @next_link_class)

    content = opts[:next_link_content] || "Next"

    if meta.has_next_page? do
      attrs = Keyword.put(attrs, :to, page_link_helper.(meta.next_page))

      link attrs do
        content
      end
    else
      attrs = Keyword.put(attrs, :disabled, "disabled")

      content_tag :span, attrs do
        content
      end
    end
  end

  @spec page_links(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  defp page_links(meta, route_func, opts) do
    page_link_opt = Keyword.fetch!(opts, :page_links)

    case page_link_opt do
      :hide ->
        raw(nil)

      :all ->
        render_page_links(meta, route_func, meta.total_pages, opts)

      {:ellipsis, max_pages} ->
        render_page_links(meta, route_func, max_pages, opts)
    end
  end

  defp render_page_links(meta, route_func, max_pages, opts) do
    aria_label = opts[:pagination_link_aria_label] || (&"Goto page #{&1}")

    link_attrs =
      opts
      |> Keyword.get(:pagination_link_attrs, [])
      |> Keyword.put_new(:class, "pagination-link")
      |> Keyword.put_new(:aria, [])

    list_attrs =
      opts
      |> Keyword.get(:pagination_list_attrs, [])
      |> Keyword.put_new(:class, "pagination-list")

    ellipsis_class =
      opts
      |> Keyword.get(:ellipsis_attrs, [])
      |> Keyword.put_new(:class, "pagination-ellipsis")

    ellipsis_content = Keyword.get(opts, :ellipsis_content, raw("&hellip;"))

    first..last =
      range =
      get_page_link_range(meta.current_page, max_pages, meta.total_pages)

    start_ellipsis =
      if first > 1,
        do: pagination_ellipsis(ellipsis_class, ellipsis_content),
        else: raw(nil)

    end_ellipsis =
      if last < meta.total_pages,
        do: pagination_ellipsis(ellipsis_class, ellipsis_content),
        else: raw(nil)

    links =
      for page <- range do
        attrs =
          link_attrs
          |> Keyword.update!(
            :aria,
            &Keyword.put(&1, :label, aria_label.(page))
          )
          |> add_current_attrs(meta.current_page == page)
          |> Keyword.put(:to, route_func.(page))

        content_tag :li do
          link(page, attrs)
        end
      end

    content_tag :ul, list_attrs do
      [start_ellipsis, links, end_ellipsis]
    end
  end

  defp get_page_link_range(current_page, max_pages, total_pages) do
    # number of additional pages to show before or after current page
    additional = ceil(max_pages / 2)

    cond do
      max_pages >= total_pages ->
        1..total_pages

      current_page + additional >= total_pages ->
        (total_pages - max_pages + 1)..total_pages

      true ->
        first = max(current_page - additional + 1, 1)
        last = min(first + max_pages - 1, total_pages)
        first..last
    end
  end

  defp pagination_ellipsis(attrs, content) do
    content_tag :li do
      content_tag :span, attrs do
        content
      end
    end
  end

  defp add_current_attrs(attrs, false), do: attrs

  defp add_current_attrs(attrs, true) do
    attrs
    |> Keyword.update!(:aria, &Keyword.put(&1, :current, "page"))
    |> Keyword.update!(:class, &"#{&1} is-current")
  end

  defp build_page_link_helper(meta, route_helper, route_helper_args) do
    filter_map =
      meta.flop.filters
      |> Stream.with_index()
      |> Enum.into(%{}, fn {filter, index} ->
        {index, Map.from_struct(filter)}
      end)

    query_params =
      []
      |> maybe_add_param(:filters, filter_map)
      |> maybe_add_param(:order_by, meta.flop.order_by)
      |> maybe_add_param(:order_directions, meta.flop.order_directions)
      |> maybe_add_param(:page_size, meta.page_size)

    fn page ->
      apply(
        route_helper,
        route_helper_args ++ [Keyword.put(query_params, :page, page)]
      )
    end
  end

  defp maybe_add_param(params, _, nil), do: params
  defp maybe_add_param(params, _, []), do: params
  defp maybe_add_param(params, key, value), do: Keyword.put(params, key, value)
end
