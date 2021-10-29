defmodule Flop.Phoenix do
  @moduledoc """
  Components for Phoenix and Flop.

  ## Introduction

  Please refer to the [Readme](README.md) for an introduction.

  ## Customization

  The default classes, attributes, texts and symbols can be overridden by
  passing the `opts` assign. Since you probably will use the same `opts` in all
  your templates, you can globally configure an `opts` provider function for
  each component.

  The functions have to return the options as a keyword list. The overrides
  are deep-merged into the default options.

      defmodule MyAppWeb.ViewHelpers do
        import Phoenix.HTML

        def pagination_opts do
           [
            ellipsis_attrs: [class: "ellipsis"],
            ellipsis_content: "‥",
            next_link_attrs: [class: "next"],
            next_link_content: next_icon(),
            page_links: {:ellipsis, 7},
            pagination_link_aria_label: &"\#{&1}ページ目へ",
            previous_link_attrs: [class: "prev"],
            previous_link_content: previous_icon()
          ]
        end

        defp next_icon do
          tag :i, class: "fas fa-chevron-right"
        end

        defp previous_icon do
          tag :i, class: "fas fa-chevron-left"
        end

        def table_opts do
          [
            container: true,
            container_attrs: [class: "table-container"],
            no_results_content: content_tag(:p, do: "Nothing found."),
            table_attrs: [class: "table"]
          ]
        end
      end

  Refer to `t:pagination_option/0` and `t:table_option/0` for a list of
  available options and defaults.

  Once you have defined these functions, you can reference them with a
  module/function tuple in `config/config.exs`.

  ```elixir
  config :flop_phoenix,
    pagination: [opts: {MyApp.ViewHelpers, :pagination_opts}],
    table: [opts: {MyApp.ViewHelpers, :table_opts}]
  ```

  ## Hiding default parameters

  Default values for page size and ordering are omitted from the query
  parameters. If you pass the `:for` assign, the Flop.Phoenix function will
  pick up the default values from the schema module deriving `Flop.Schema`.

  ## Links

  Links are generated with `Phoenix.LiveView.Helpers.live_patch/2`. This will
  lead to `<a>` tags with `data-phx-link` and `data-phx-link-state` attributes,
  which will be ignored outside of LiveViews and LiveComponents.

  When used in LiveView templates, you will need to handle the new params in the
  `handle_params/3` callback of your LiveView module.

  ## Event-Based Pagination and Sorting

  To make `Flop.Phoenix` use event based pagination and sorting, you need to
  assign the `:event` to the pagination and table generators. This will
  generate an `<a>` tag with `phx-click` and `phx-value` attributes set.

  You can set a different target by assigning a `:target`. The value
  will be used in the `phx-target` attribute.

      <Flop.Phoenix.pagination
        for={MyApp.Pet}
        meta={@meta}
        event="paginate-pets"
        target={@myself}
      />

  You will need to handle the event in the `handle_event/3` callback of your
  LiveView module. The event name will be the one you set with the `:event`
  option.

      def handle_event("paginate-pets", %{"page" => page}, socket) do
        flop = Flop.set_page(socket.assigns.meta.flop, page)

        with {:ok, {pets, meta}} <- Pets.list_pets(params) do
          {:noreply, assign(socket, pets: pets, meta: meta)}
        end
      end

      def handle_event("order_pets", %{"order" => order}, socket) do
        flop = Flop.push_order(socket.assigns.meta.flop, order)

        with {:ok, {pets, meta}} <- Pets.list_pets(flop) do
          {:noreply, assign(socket, pets: pets, meta: meta)}
        end
      end
  """

  use Phoenix.Component
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  alias Flop.Meta
  alias Flop.Phoenix.Pagination
  alias Flop.Phoenix.Table

  @typedoc """
  Defines the available options for `Flop.Phoenix.pagination/1`.

  - `:current_link_attrs` - The attributes for the link to the current page.
    Default: `#{inspect(Pagination.default_opts()[:current_link_attrs])}`.
  - `:ellipsis_attrs` - The attributes for the `<span>` that wraps the
    ellipsis.
    Default: `#{inspect(Pagination.default_opts()[:ellipsis_attrs])}`.
  - `:ellipsis_content` - The content for the ellipsis element.
    Default: `#{inspect(Pagination.default_opts()[:ellipsis_content])}`.
  - `:next_link_attrs` - The attributes for the link to the next page.
    Default: `#{inspect(Pagination.default_opts()[:next_link_attrs])}`.
  - `:next_link_content` - The content for the link to the next page.
    Default: `#{inspect(Pagination.default_opts()[:next_link_content])}`.
  - `:page_links` - Specifies how many page links should be rendered.
    Default: `#{inspect(Pagination.default_opts()[:page_links])}`.
    - `:all` - Renders all page links.
    - `{:ellipsis, n}` - Renders `n` page links. Renders ellipsis elements if
      there are more pages than displayed.
    - `:hide` - Does not render any page links.
  - `:pagination_link_aria_label` - 1-arity function that takes a page number
    and returns an aria label for the corresponding page link.
    Default: `&"Go to page \#{&1}"`.
  - `:pagination_link_attrs` - The attributes for the pagination links.
    Default: `#{inspect(Pagination.default_opts()[:pagination_link_attrs])}`.
  - `:pagination_list_attrs` - The attributes for the pagination list.
    Default: `#{inspect(Pagination.default_opts()[:pagination_list_attrs])}`.
  - `:previous_link_attrs` - The attributes for the link to the previous page.
    Default: `#{inspect(Pagination.default_opts()[:previous_link_attrs])}`.
  - `:previous_link_content` - The content for the link to the previous page.
    Default: `#{inspect(Pagination.default_opts()[:previous_link_content])}`.
  - `:wrappers_attrs` - The attributes for the `<nav>` element that wraps the
    pagination links.
    Default: `#{inspect(Pagination.default_opts()[:wrappers_attrs])}`.
  """
  @type pagination_option ::
          {:current_link_attrs, keyword}
          | {:ellipsis_attrs, keyword}
          | {:ellipsis_content, Phoenix.HTML.safe() | binary}
          | {:next_link_attrs, keyword}
          | {:next_link_content, Phoenix.HTML.safe() | binary}
          | {:page_links, :all | :hide | {:ellipsis, pos_integer}}
          | {:pagination_link_aria_label, (pos_integer -> binary)}
          | {:pagination_link_attrs, keyword}
          | {:pagination_list_attrs, keyword}
          | {:previous_link_attrs, keyword}
          | {:previous_link_content, Phoenix.HTML.safe() | binary}
          | {:wrapper_attrs, keyword}

  @typedoc """
  Defines the available options for `Flop.Phoenix.table/1`.

  - `:container` - Wraps the table in a `<div>` if `true`.
    Default: `#{inspect(Table.default_opts()[:container])}`.
  - `:container_attrs` - The attributes for the table container.
    Default: `#{inspect(Table.default_opts()[:container_attrs])}`.
  - `:no_results_content` - Any content that should be rendered if there are no
    results. Default: `#{inspect(Table.default_opts()[:no_results_content])}`.
  - `:table_attrs` - The attributes for the `<table>` element.
    Default: `#{inspect(Table.default_opts()[:table_attrs])}`.
  - `:th_wrapper_attrs` - The attributes for the `<span>` element that wraps the
    header link and the order direction symbol.
    Default: `#{inspect(Table.default_opts()[:th_wrapper_attrs])}`.
  - `:symbol_asc` - The symbol that is used to indicate that the column is
    sorted in ascending order.
    Default: `#{inspect(Table.default_opts()[:symbol_asc])}`.
  - `:symbol_attrs` - The attributes for the `<span>` element that wraps the
    order direction indicator in the header columns.
    Default: `#{inspect(Table.default_opts()[:symbol_attrs])}`.
  - `:symbol_desc` - The symbol that is used to indicate that the column is
    sorted in ascending order.
    Default: `#{inspect(Table.default_opts()[:symbol_desc])}`.
  - `:tbody_td_attrs`: Attributes to added to each `<td>` tag within the
    `<tbody>`. Default: `#{inspect(Table.default_opts()[:tbody_td_attrs])}`.
  - `:tbody_tr_attrs`: Attributes to added to each `<tr>` tag within the
    `<tbody>`. Default: `#{inspect(Table.default_opts()[:tbody_tr_attrs])}`.
  - `:thead_th_attrs`: Attributes to added to each `<th>` tag within the
    `<thead>`. Default: `#{inspect(Table.default_opts()[:thead_th_attrs])}`.
  - `:thead_tr_attrs`: Attributes to added to each `<tr>` tag within the
    `<thead>`. Default: `#{inspect(Table.default_opts()[:thead_tr_attrs])}`.
  """
  @type table_option ::
          {:container, boolean}
          | {:container_attrs, keyword}
          | {:no_results_content, Phoenix.HTML.safe() | binary}
          | {:symbol_asc, Phoenix.HTML.safe() | binary}
          | {:symbol_attrs, keyword}
          | {:symbol_desc, Phoenix.HTML.safe() | binary}
          | {:table_attrs, keyword}
          | {:tbody_td_attrs, keyword}
          | {:tbody_tr_attrs, keyword}
          | {:th_wrapper_attrs, keyword}
          | {:thead_th_attrs, keyword}
          | {:thead_tr_attrs, keyword}

  @doc """
  Generates a pagination element.

  ## Assigns

  - `meta` - The meta information of the query as returned by the `Flop` query
    functions.
  - `path_helper` - The path helper to use for building the link URL. Can be an
    mfa tuple or a function/args tuple. If set, links will be rendered with
    `live_patch/2` and the parameters have to be handled in the `handle_params/3`
    callback of the LiveView module.
  - `event` - If set, `Flop.Phoenix` will render links with a `phx-click`
    attribute.
  - `for` (optional) - The schema module deriving `Flop.Schema`. If set,
    `Flop.Phoenix` will remove default parameters from the query parameters.

  - `target` (optional) - Sets the `phx-target` attribute for the pagination
    links.
  - `opts` (optional) - Options to customize the pagination. See
    `t:Flop.Phoenix.pagination_option/0`. Note that the options passed to the
    function are deep merged into the default options. These options will
    likely be the same for all the tables in a project, so it probably makes
    sense to define them once in a function or set them in a wrapper function
    as described in the `Customization` section of the module documentation.

  ## Page link options

  By default, page links for all pages are shown. You can limit the number of
  page links or disable them altogether by passing the `:page_links` option.

  - `:all`: Show all page links (default).
  - `:hide`: Don't show any page links. Only the previous/next links will be
    shown.
  - `{:ellipsis, x}`: Limits the number of page links. The first and last page
    are always displayed. The `x` refers to the number of additional page links
    to show.

  ## Pagination link aria label

  For the page links, there is the `:pagination_link_aria_label` option to set
  the aria label. Since the page number is usually part of the aria label, you
  need to pass a function that takes the page number as an integer and returns
  the label as a string. The default is `&"Goto page \#{&1}"`.

  ## Previous/next links

  By default, the previous and next links contain the texts `Previous` and
  `Next`. To change this, you can pass the `:previous_link_content` and
  `:next_link_content` options.

  See the module documentation and [Readme](README.md) for examples.
  """
  @doc section: :generators
  @spec pagination(map) :: Phoenix.LiveView.Rendered.t()
  def pagination(assigns) do
    assigns = Pagination.init_assigns(assigns)

    ~H"""
    <%= if @meta.total_pages > 1 do %>
      <Pagination.render
        event={@event}
        meta={@meta}
        opts={@opts}
        page_link_helper={
          Pagination.build_page_link_helper(@meta, @path_helper, @for)
        }
        target={@target}
      />
    <% end %>
    """
  end

  @doc """
  Generates a table with sortable columns.

  ## Example

  ```elixir
  <Flop.Phoenix.table
    for={MyApp.Pet}
    items={@pets}
    meta={@meta}
    path_helper={{Routes, :pet_path, [@socket, :index]}}
  >
    <:col let={pet} label="Name" field={:name}><%= pet.name %></:col>
    <:col let={pet} label="Age" field={:age}><%= pet.age %></:col>
  </Flop.Phoenix.table>
  ```

  ## Assigns

  - `items` - The list of items to be displayed in rows. This is the result list
    returned by the query.
  - `meta` - The `Flop.Meta` struct returned by the query function.
  - `path_helper` - The path helper to use for building the link URL. Can be an
    mfa tuple or a function/args tuple. If set, links will be rendered with
    `live_path/2` and the parameters have to be handled in the `handle_params/3`
    callback of the LiveView module.
  - `event` - If set, `Flop.Phoenix` will render links with a `phx-click`
    attribute.
  - `for` (optional) - The schema module deriving `Flop.Schema`. If set, header
    links are only added for fields that are defined as sortable and query
    parameters are hidden if they match the default order.
  - `event` (optional) - If set, `Flop.Phoenix` will render links with a
    `phx-click` attribute.
  - `target` (optional) - Sets the `phx-target` attribute for the header links.
  - `opts` (optional) - Keyword list with additional options (see
    `t:Flop.Phoenix.table_option/0`). Note that the options passed to the
    function are deep merged into the default options. These options will
    likely be the same for all the tables in a project, so it probably makes
    sense to define them once in a function or set them in a wrapper function
    as described in the `Customization` section of the module documentation.

  ## Col slot

  For each column to render, add one `<:col>` element.

  ```elixir
  <:col let={pet} label="Name" field={:name}><%= pet.name %></:col>
  ```

  - `label` - The content for the header column.
  - `field` (optional) - The field name for sorting.

  ## Foot slot

  You can optionally add a `foot`. The inner block will be rendered inside
  a `tfoot` element.

      <Flop.Phoenix.table>
        <:foot>
          <tr><td>Total: <span class="total"><%= @total %></span></td></tr>
        </:foot>
      </Flop.Phoenix.table>

  See the module documentation and [Readme](README.md) for more examples.
  """
  @doc since: "0.6.0"
  @doc section: :generators
  @spec table(map) :: Phoenix.LiveView.Rendered.t()
  def table(assigns) do
    assigns = Table.init_assigns(assigns)

    ~H"""
    <%= if @items == [] do %>
      <%= @opts[:no_results_content] %>
    <% else %>
      <%= if @opts[:container] do %>
        <div {@opts[:container_attrs]}>
          <Table.render
            col={@col}
            foot={@foot}
            for={@for}
            event={@event}
            items={@items}
            meta={@meta}
            opts={@opts}
            path_helper={@path_helper}
            target={@target}
          />
        </div>
      <% else %>
        <Table.render
          col={@col}
          foot={@foot}
          for={@for}
          event={@event}
          items={@items}
          meta={@meta}
          opts={@opts}
          path_helper={@path_helper}
          target={@target}
        />
      <% end %>
    <% end %>
    """
  end

  @doc """
  Converts a Flop struct into a keyword list that can be used as a query with
  Phoenix route helper functions.

  Default limits and default order parameters set via the application
  environment are omitted. You can pass the `:for` option to pick up the
  default options from a schema module deriving `Flop.Schema`. You can also
  pass `default_limit` and `default_order` as options directly. The function
  uses `Flop.get_option/2` internally to retrieve the default options.

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

      iex> f = %Flop{page: 5, page_size: 20}
      iex> to_query(f, default_limit: 20)
      [page: 5]
  """
  @doc since: "0.6.0"
  @doc section: :miscellaneous
  @spec to_query(Flop.t()) :: keyword
  def to_query(%Flop{filters: filters} = flop, opts \\ []) do
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
      :offset,
      :page
    ]

    default_limit = Flop.get_option(:default_limit, opts)
    default_order = Flop.get_option(:default_order, opts)

    keys
    |> Enum.reduce([], &maybe_add_param(&2, &1, Map.get(flop, &1)))
    |> maybe_add_param(:page_size, flop.page_size, default_limit)
    |> maybe_add_param(:limit, flop.limit, default_limit)
    |> maybe_add_order_params(flop, default_order)
    |> maybe_add_param(:filters, filter_map)
  end

  defp maybe_add_param(params, key, value, default \\ nil)
  defp maybe_add_param(params, _, nil, _), do: params
  defp maybe_add_param(params, _, [], _), do: params
  defp maybe_add_param(params, _, map, _) when map == %{}, do: params
  defp maybe_add_param(params, :page, 1, _), do: params
  defp maybe_add_param(params, :offset, 0, _), do: params
  defp maybe_add_param(params, _, val, val), do: params
  defp maybe_add_param(params, key, val, _), do: Keyword.put(params, key, val)

  defp maybe_add_order_params(
         params,
         %Flop{order_by: order_by, order_directions: order_directions},
         %{order_by: order_by, order_directions: order_directions}
       ),
       do: params

  defp maybe_add_order_params(
         params,
         %Flop{order_by: order_by, order_directions: order_directions},
         _
       ) do
    params
    |> maybe_add_param(:order_by, order_by)
    |> maybe_add_param(:order_directions, order_directions)
  end

  @doc """
  Builds a path that includes query parameters for the given `Flop` struct
  using the referenced Phoenix path helper function.

  The first argument can be either an MFA tuple (module, function name as atom,
  arguments) or a 2-tuple (function, arguments).

  Default values for `limit`, `page_size`, `order_by` and `order_directions` are
  omitted from the query parameters. To pick up the default parameters from a
  schema module deriving `Flop.Schema`, you need to pass the `:for` option.

  ## Examples

      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path(
      ...>   {Flop.PhoenixTest, :route_helper, [%Plug.Conn{}, :pets]},
      ...>   flop
      ...> )
      "/pets?page_size=10&page=2"

      iex> pet_path = fn _conn, :index, query ->
      ...>   "/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path({pet_path, [%Plug.Conn{}, :index]}, flop)
      "/pets?page_size=10&page=2"

  We're defining fake path helpers for the scope of the doctests. In a real
  Phoenix application, you would pass something like
  `{Routes, :pet_path, args}` or `{&Routes.pet_path/3, args}` as the
  first argument.

  You can also pass a `Flop.Meta` struct or a keyword list as the third
  argument.

      iex> pet_path = fn _conn, :index, query ->
      ...>   "/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> meta = %Flop.Meta{flop: flop}
      iex> build_path({pet_path, [%Plug.Conn{}, :index]}, meta)
      "/pets?page_size=10&page=2"
      iex> query_params = to_query(flop)
      iex> build_path({pet_path, [%Plug.Conn{}, :index]}, query_params)
      "/pets?page_size=10&page=2"

  If the path helper takes additional path parameters, just add them to the
  second argument.

      iex> user_pet_path = fn _conn, :index, id, query ->
      ...>   "/users/\#{id}/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path({user_pet_path, [%Plug.Conn{}, :index, 123]}, flop)
      "/users/123/pets?page_size=10&page=2"

  If the last path helper argument is a query parameter list, the Flop
  parameters are merged into it.

      iex> pet_url = fn _conn, :index, query ->
      ...>   "https://pets.flop/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{order_by: :name, order_directions: [:desc]}
      iex> build_path({pet_url, [%Plug.Conn{}, :index, [user_id: 123]]}, flop)
      "https://pets.flop/pets?user_id=123&order_directions[]=desc&order_by=name"
      iex> build_path(
      ...>   {pet_url,
      ...>    [%Plug.Conn{}, :index, [category: "small", user_id: 123]]},
      ...>   flop
      ...> )
      "https://pets.flop/pets?category=small&user_id=123&order_directions[]=desc&order_by=name"
  """
  @doc since: "0.6.0"
  @doc section: :miscellaneous
  @spec build_path(
          {module, atom, [any]} | {function, [any]},
          Meta.t() | Flop.t() | keyword,
          keyword
        ) ::
          String.t()
  def build_path(tuple, meta_or_flop_or_params, opts \\ [])

  def build_path(tuple, %Meta{flop: flop}, opts),
    do: build_path(tuple, flop, opts)

  def build_path(tuple, %Flop{} = flop, opts) do
    build_path(tuple, Flop.Phoenix.to_query(flop, opts))
  end

  def build_path({module, func, args}, flop_params, _opts)
      when is_atom(module) and
             is_atom(func) and
             is_list(args) and
             is_list(flop_params) do
    final_args = build_final_args(args, flop_params)
    apply(module, func, final_args)
  end

  def build_path({func, args}, flop_params, _opts)
      when is_function(func) and
             is_list(args) and
             is_list(flop_params) do
    final_args = build_final_args(args, flop_params)
    apply(func, final_args)
  end

  defp build_final_args(args, flop_params) do
    case Enum.reverse(args) do
      [last_arg | rest] when is_list(last_arg) ->
        query_arg = Keyword.merge(last_arg, flop_params)
        Enum.reverse([query_arg | rest])

      _ ->
        args ++ [flop_params]
    end
  end
end
