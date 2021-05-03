defmodule Flop.Phoenix do
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

  To make the `Flop.Phoenix` functions available in all templates, locate the
  `view_helpers/0` macro in `my_app_web.ex` and add another import statement:

      defp view_helpers do
        quote do
          # ...

          import Flop.Phoenix

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

  The second argument of `Flop.Phoenix.pagination/4` is the route helper
  function, and the third argument is a list of arguments for that route helper.
  If you want to add path parameters, you can do that like this:

      <%= pagination(@meta, &Routes.owner_pet_path/4, [@conn, :index, @owner]) %>

  ## Customization

  `Flop.Phoenix` sets some default classes and aria attributes.

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

        def pagination(meta, path_helper, path_helper_args) do
          Flop.Phoenix.pagination(
            meta,
            path_helper,
            path_helper_args,
            pagination_opts()
          )
        end

        def pagination_opts do
          [
            # ...
          ]
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

  ### Page link options

  By default, page links for all pages are show. You can limit the number of
  page links or disable them altogether by passing the `:page_links` option.

  - `:all`: Show all page links (default).
  - `:hide`: Don't show any page links. Only the previous/next links will be
    shown.
  - `{:ellipsis, x}`: Limits the number of page links. The first and last page
    are always displayed. The `x` refers to the number of additional page links
    to show.

  ### Attributes and CSS classes

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

  ### Pagination link aria label

  For the page links, there is the `:pagination_link_aria_label` option to set
  the aria label. Since the page number is usually part of the aria label, you
  need to pass a function that takes the page number as an integer and returns
  the label as a string. The default is `&"Goto page \#{&1}"`.

  ### Previous/next links

  By default, the previous and next links contain the texts `Previous` and
  `Next`. To change this, you can pass the `:previous_link_content` and
  `:next_link_content` options.

  ### Customization example

      def pagination(meta, path_helper, path_helper_args) do
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

        Flop.Phoenix.pagination(meta, path_helper, path_helper_args, opts)
      end

      defp next_icon do
        content_tag :i, class: "fas fa-chevron-right" do
        end
      end

      defp previous_icon do
        content_tag :i, class: "fas fa-chevron-left" do
        end
      end

  ## Sortable table

  To add a sortable table for pets on the same page, define a function in
  `MyAppWeb.PetView` that returns the table headers:

      def table_headers do
        ["ID", {"Name", :name}, {"Age", :age}, ""]
      end

  This defines four header columns: One for the ID, which is not sortable, and
  columns for the name and the age, which are both sortable, and a fourth
  column without a header value. The last column will hold the links to the
  detail pages. The name and age column headers will be linked, so that they the
  order on the `:name` and `:age` field, respectively.

  Next, we define a function that returns the column values for a single pet:

      def table_row(%Pet{id: id, name: name, age: age}, opts) do
        conn = Keyword.fetch!(opts, :conn)
        [id, name, age, link("show", to: Routes.pet_path(conn, :show, id))]
      end

  The controller already assigns the pets and the meta struct to the conn. All
  that's left to do is to add the table to the index template:

      <%= table(%{
            items: @pets,
            meta: @meta,
            path_helper: &Routes.pet_path/3,
            path_helper_args: [@conn, :index],
            headers: table_headers(),
            row_func: &table_row/2,
            opts: [conn: @conn]
        })
      %>

  ## LiveView

  The functions in this module can be used in both `.eex` and `.leex` templates.

  Links are generated with `Phoenix.LiveView.Helpers.live_patch/2`. This will
  lead to `<a>` tags with `data-phx-link` and `data-phx-link-state` attributes,
  which will be ignored in `.eex` templates. When used in LiveView templates,
  you will need to handle the new params in the `handle_params/3` callback of
  your LiveView module.
  """

  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  alias Flop.Meta
  alias Flop.Phoenix.Pagination
  alias Flop.Phoenix.Table

  @doc """
  Generates a pagination element.

  - `meta`: The meta information of the query as returned by the `Flop` query
    functions.
  - `path_helper`: The path helper function that builds a path to the current
    page, e.g. `&Routes.pet_path/3`.
  - `path_helper_args`: The arguments to be passed to the route helper
    function, e.g. `[@conn, :index]`. The page number and page size will be
    added as query parameters.
  - `opts`: Options to customize the pagination. See section Customization.

  See the module documentation for examples.
  """
  @doc section: :generators
  @spec pagination(Meta.t(), function, [any], keyword) ::
          Phoenix.LiveView.Rendered.t()

  def pagination(meta, path_helper, path_helper_args, opts \\ [])

  def pagination(%Meta{total_pages: p}, _, _, _) when p <= 1, do: raw(nil)

  def pagination(%Meta{} = meta, path_helper, path_helper_args, opts) do
    assigns = %{
      __changed__: nil,
      meta: meta,
      opts: Pagination.init_opts(opts),
      page_link_helper:
        Pagination.build_page_link_helper(meta, path_helper, path_helper_args)
    }

    ~L"""
    <%= if @meta.total_pages > 1 do %>
      <%= content_tag :nav, Pagination.build_attrs(@opts) do %>
        <%= Pagination.previous_link(@meta, @page_link_helper, @opts) %>
        <%= Pagination.next_link(@meta, @page_link_helper, @opts) %>
        <%= Pagination.page_links(@meta, @page_link_helper, @opts) %>
      <% end %>
    <% end %>
    """
  end

  @doc """
  Generates a table with sortable columns.

  The argument is a map with the following keys:

  - `headers`: A list of header columns. Can be a list of strings (or markup),
    or a list of `{value, field_name}` tuples.
  - `items`: The list of items to be displayed in rows. This is the result list
    returned by the query.
  - `meta`: The `Flop.Meta` struct returned by the query function.
  - `path_helper`: The Phoenix path or url helper that leads to the current
    page.
  - `path_helper_args`: The argument list for the path helper. For example, if
    you would call `Routes.pet_path(@conn, :index)` to generate the path for the
    current page, this would be `[@conn, :index]`.
  - `opts`: Keyword list with additional options (see below). This list will
    also be passed as the second argument to the row function.
  - `row_func`: A function that takes one item of the `items` list and the
    `opts` and returns the column values for that item's row.

  ## Available options

  - `:for` - The schema module deriving `Flop.Schema`. If set, header links are
    only added for fields that are defined as sortable.
  - `:table_class` - The CSS class for the `<table>` element. No default.
  - `:symbol_class` - The CSS class for the `<span>` element that wraps the
    order direction indicator in the header columns. Defaults to
    `"order-direction"`.
  - `:symbol_asc` - The symbol that is used to indicate that the column is
    sorted in ascending order. Defaults to `"▴"`.
  - `:symbol_desc` - The symbol that is used to indicate that the column is
    sorted in ascending order. Defaults to `"▾"`.
  - `:container` - Wraps the table in a `<div>` if `true`. Defaults to `false`.
  - `:container_class` - The CSS class for the table container. Defaults to
    `"table-container"`.

  See the module documentation for examples.
  """
  @doc since: "0.6.0"
  @doc section: :generators
  @spec table(map) :: Phoenix.LiveView.Rendered.t()
  def table(assigns) do
    ~L"""
    <%= unless @items == [] do %>
      <%= if @opts[:container] do %>
        <div class="<%= Keyword.get(@opts, :container_class, "table-container") %>">
          <%= Table.render(assigns) %>
        </div>
      <% else %>
        <%= Table.render(assigns) %>
      <% end %>
    <% end %>
    """
  end

  @doc """
  Converts a Flop struct into a keyword list that can be used as a query with
  Phoenix route helper functions.

  ## Examples

      iex> to_query(%Flop{})
      []

      iex> f = %Flop{order_by: [:name, :age], order_directions: [:desc, :asc]}
      iex> to_query(f)
      [order_directions: [:desc, :asc], order_by: [:name, :age]]
      iex> f |> to_query |> Plug.Conn.Query.encode()
      "order_directions[]=desc&order_directions[]=asc&order_by[]=name&order_by[]=age"

      iex> f = %Flop{page: 5, page_size: 20}
      iex> to_query(f)
      [page_size: 20, page: 5]

      iex> f = %Flop{first: 20, after: "g3QAAAABZAAEbmFtZW0AAAAFQXBwbGU="}
      iex> to_query(f)
      [first: 20, after: "g3QAAAABZAAEbmFtZW0AAAAFQXBwbGU="]

      iex> f = %Flop{
      ...>   filters: [
      ...>     %Flop.Filter{field: :name, op: :=~, value: "Mag"},
      ...>     %Flop.Filter{field: :age, op: :>, value: 25}
      ...>   ]
      ...> }
      iex> to_query(f)
      [
        filters: %{
          0 => %{field: :name, op: :=~, value: "Mag"},
          1 => %{field: :age, op: :>, value: 25}
        }
      ]
      iex> f |> to_query() |> Plug.Conn.Query.encode()
      "filters[0][field]=name&filters[0][op]=%3D~&filters[0][value]=Mag&filters[1][field]=age&filters[1][op]=%3E&filters[1][value]=25"
  """
  @doc since: "0.6.0"
  @doc section: :miscellaneous
  @spec to_query(Flop.t()) :: keyword
  def to_query(%Flop{filters: filters} = flop) do
    filter_map =
      filters
      |> Stream.with_index()
      |> Enum.into(%{}, fn {filter, index} ->
        {index, Map.from_struct(filter)}
      end)

    keys = [
      :after,
      :before,
      :first,
      :last,
      :limit,
      :offset,
      :order_by,
      :order_directions,
      :page,
      :page_size
    ]

    keys
    |> Enum.reduce([], &maybe_add_param(&2, &1, Map.get(flop, &1)))
    |> maybe_add_param(:filters, filter_map)
  end

  defp maybe_add_param(params, _, nil), do: params
  defp maybe_add_param(params, _, []), do: params
  defp maybe_add_param(params, _, map) when map == %{}, do: params
  defp maybe_add_param(params, key, value), do: Keyword.put(params, key, value)

  @doc """
  Takes a Phoenix path helper function and a list of path helper arguments and
  builds a path that includes query parameters for the given `Flop` struct.

  ## Examples

      iex> pet_path = fn _conn, :index, query ->
      ...>   "/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path(pet_path, [%Plug.Conn{}, :index], flop)
      "/pets?page_size=10&page=2"

  We're defining fake path helpers for the scope of the doctests. In a real
  Phoenix application, you would pass something like `&Routes.pet_path/3` as the
  first argument.

  You can also pass a `Flop.Meta` struct or a keyword list as the third
  argument.

      iex> pet_path = fn _conn, :index, query ->
      ...>   "/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> meta = %Flop.Meta{flop: flop}
      iex> build_path(pet_path, [%Plug.Conn{}, :index], meta)
      "/pets?page_size=10&page=2"
      iex> query_params = to_query(flop)
      iex> build_path(pet_path, [%Plug.Conn{}, :index], query_params)
      "/pets?page_size=10&page=2"

  If the path helper takes additional path parameters, just add them to the
  second argument.

      iex> user_pet_path = fn _conn, :index, id, query ->
      ...>   "/users/\#{id}/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path(user_pet_path, [%Plug.Conn{}, :index, 123], flop)
      "/users/123/pets?page_size=10&page=2"

  If the last path helper argument is a query parameter list, the Flop
  parameters are merged into it.

      iex> pet_url = fn _conn, :index, query ->
      ...>   "https://pets.flop/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{order_by: :name, order_directions: [:desc]}
      iex> build_path(pet_url, [%Plug.Conn{}, :index, [user_id: 123]], flop)
      "https://pets.flop/pets?user_id=123&order_directions[]=desc&order_by=name"
      iex> build_path(
      ...>   pet_url,
      ...>   [%Plug.Conn{}, :index, [category: "small", user_id: 123]],
      ...>   flop
      ...> )
      "https://pets.flop/pets?category=small&user_id=123&order_directions[]=desc&order_by=name"
  """

  @doc since: "0.6.0"
  @doc section: :miscellaneous
  @spec build_path(function, [any], Meta.t() | Flop.t() | keyword) :: String.t()
  def build_path(path_helper, args, %Meta{flop: flop}),
    do: build_path(path_helper, args, flop)

  def build_path(path_helper, args, %Flop{} = flop) do
    build_path(path_helper, args, Flop.Phoenix.to_query(flop))
  end

  def build_path(path_helper, args, flop_params)
      when is_function(path_helper) and
             is_list(args) and
             is_list(flop_params) do
    final_args =
      case Enum.reverse(args) do
        [last_arg | rest] when is_list(last_arg) ->
          query_arg = Keyword.merge(last_arg, flop_params)
          Enum.reverse([query_arg | rest])

        _ ->
          args ++ [flop_params]
      end

    apply(path_helper, final_args)
  end
end
