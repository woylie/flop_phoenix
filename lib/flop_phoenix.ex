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

  When used within a LiveView or LiveComponent, you will need to handle the new
  params in the `c:Phoenix.LiveView.handle_params/3` callback of your LiveView
  module.

  ## Event-Based Pagination and Sorting

  To make `Flop.Phoenix` use event based pagination and sorting, you need to
  assign the `:event` to the pagination and table components. This will
  generate an `<a>` tag with `phx-click` and `phx-value` attributes set.

  You can set a different target by assigning a `:target`. The value
  will be used as the `phx-target` attribute.

      <Flop.Phoenix.pagination
        meta={@meta}
        event="paginate-pets"
        target={@myself}
      />

  You will need to handle the event in the `c:Phoenix.LiveView.handle_event/3`
  or `c:Phoenix.LiveComponent.handle_event/3` callback of your
  LiveView or LiveComponent module. The event name will be the one you set with
  the `:event` option.

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

  alias Flop.Filter
  alias Flop.Meta
  alias Flop.Phoenix.CursorPagination
  alias Flop.Phoenix.Misc
  alias Flop.Phoenix.Pagination
  alias Flop.Phoenix.Table
  alias Phoenix.HTML.Form

  @typedoc """
  Defines the available options for `Flop.Phoenix.pagination/1`.

  - `:current_link_attrs` - The attributes for the link to the current page.
    Default: `#{inspect(Pagination.default_opts()[:current_link_attrs])}`.
  - `:disabled` - The class which is added to disabled links. Default:
    `#{inspect(Pagination.default_opts()[:disabled_class])}`.
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
          | {:disabled_class, String.t()}
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
  Defines the available options for `Flop.Phoenix.cursor_pagination/1`.

  - `:disabled` - The class which is added to disabled links. Default:
    `#{inspect(CursorPagination.default_opts()[:disabled_class])}`.
  - `:next_link_attrs` - The attributes for the link to the next page.
    Default: `#{inspect(CursorPagination.default_opts()[:next_link_attrs])}`.
  - `:next_link_content` - The content for the link to the next page.
    Default: `#{inspect(CursorPagination.default_opts()[:next_link_content])}`.
  - `:previous_link_attrs` - The attributes for the link to the previous page.
    Default: `#{inspect(CursorPagination.default_opts()[:previous_link_attrs])}`.
  - `:previous_link_content` - The content for the link to the previous page.
    Default: `#{inspect(CursorPagination.default_opts()[:previous_link_content])}`.
  - `:wrappers_attrs` - The attributes for the `<nav>` element that wraps the
    pagination links.
    Default: `#{inspect(CursorPagination.default_opts()[:wrappers_attrs])}`.
  """
  @type cursor_pagination_option ::
          {:disabled_class, String.t()}
          | {:next_link_attrs, keyword}
          | {:next_link_content, Phoenix.HTML.safe() | binary}
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
    results. Default: `<p>No results.</p>`.
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

  ## Example

      <Flop.Phoenix.pagination
        meta={@meta}
        path_helper={{Routes, :pet_path, [@socket, :index]}}
      />

  ## Assigns

  - `meta` - The meta information of the query as returned by the `Flop` query
    functions.
  - `path_helper` - The path helper to use for building the link URL. Can be an
    mfa tuple or a function/args tuple. If set, links will be rendered with
    `live_patch/2` and the parameters have to be handled in the `handle_params/3`
    callback of the LiveView module.
  - `event` - If set, `Flop.Phoenix` will render links with a `phx-click`
    attribute.
  - `target` (optional) - Sets the `phx-target` attribute for the pagination
    links.
  - `opts` (optional) - Options to customize the pagination. See
    `t:Flop.Phoenix.pagination_option/0`. Note that the options passed to the
    function are deep merged into the default options. These options will
    likely be the same for all the tables in a project, so it probably makes
    sense to define them once in a function or set them in a wrapper function
    as described in the `Customization` section of the module documentation.

  ## Hiding default parameters

  If you pass the `for` option to the Flop query function, Flop Phoenix hides
  the `order` and `page_size` parameters if they match the default values defined
  with `Flop.Schema`.

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
  """
  @doc section: :components
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
          Pagination.build_page_link_helper(@meta, @path_helper)
        }
        target={@target}
      />
    <% end %>
    """
  end

  @doc """
  Renders a cursor pagination element.

  ## Example

      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        path_helper={{Routes, :pet_path, [@socket, :index]}}
      />

  ## Assigns

  - `meta` - The meta information of the query as returned by the `Flop` query
    functions.
  - `path_helper` - The path helper to use for building the link URL. Can be an
    mfa tuple or a function/args tuple. If set, links will be rendered with
    `live_patch/2` and the parameters have to be handled in the `handle_params/3`
    callback of the LiveView module.
  - `event` - If set, `Flop.Phoenix` will render links with a `phx-click`
    attribute.
  - `target` (optional) - Sets the `phx-target` attribute for the pagination
    links.
  - `reverse` (optional) - By default, the `next` link moves forward with the
    `:after` parameter set to the end cursor, and the `previous` link moves
    backward with the `:before` parameter set to the start cursor. If `reverse`
    is set to `true`, the destinations of the links are switched.
  - `opts` (optional) - Options to customize the pagination. See
    `t:Flop.Phoenix.cursor_pagination_option/0`. Note that the options passed to
    the function are deep merged into the default options. These options will
    likely be the same for all the tables in a project, so it probably makes
    sense to define them once in a function or set them in a wrapper function
    as described in the `Customization` section of the module documentation.

  ## Hiding default parameters

  If you pass the `for` option to the Flop query function, Flop Phoenix hides
  the `order` and `page_size` parameters if they match the default values
  defined with `Flop.Schema`.

  ## Previous/next links

  By default, the previous and next links contain the texts `Previous` and
  `Next`. To change this, you can pass the `:previous_link_content` and
  `:next_link_content` options.

  ## Getting the right parameters from Flop

  This component requires the start and end cursors to be set in `Flop.Meta`. If
  you pass a `Flop.Meta` struct with page or offset-based parameters, this will
  result in an error. You can enforce cursor-based pagination in your query
  function with the `default_pagination_type` and `pagination_types` options.

      def list_users(params) do
        Flop.validate_and_run(Pet, params,
          for: Pet,
          default_pagination_type: :first,
          pagination_types: [:first, :last]
        )
      end

  `default_pagination_type` ensures that Flop defaults to the right pagination
  type when it cannot determine the type from the parameters. `pagination_types`
  ensures that parameters for other types are not accepted.

  ## Order fields

  The pagination cursor is based on the `ORDER BY` fields of the query. It is
  important that the combination of order fields is unique across the data set.
  You can use:

  - the field with the primary key
  - a field with a unique index
  - all fields of a composite primary key or unique index

  If you want to order by fields that are not unique, you can add the primary
  key as the last order field. For example, if you want to order by family name
  and given name, you should set the `order_by` parameter to
  `[:family_name, :given_name, :id]`.
  """
  @doc section: :components
  @spec cursor_pagination(map) :: Phoenix.LiveView.Rendered.t()
  def cursor_pagination(assigns) do
    assigns = CursorPagination.init_assigns(assigns)

    ~H"""
    <%= unless @meta.errors != [] do %>
      <nav {@opts[:wrapper_attrs]}>
        <CursorPagination.render_link
          attrs={@opts[:previous_link_attrs]}
          content={@opts[:previous_link_content]}
          direction={if @reverse, do: :next, else: :previous}
          event={@event}
          meta={@meta}
          path_helper={@path_helper}
          opts={@opts}
          target={@target}
        />
        <CursorPagination.render_link
          attrs={@opts[:next_link_attrs]}
          content={@opts[:next_link_content]}
          direction={if @reverse, do: :previous, else: :next}
          event={@event}
          meta={@meta}
          path_helper={@path_helper}
          opts={@opts}
          target={@target}
        />
      </nav>
    <% end %>
    """
  end

  @doc """
  Generates a table with sortable columns.

  ## Example

  ```elixir
  <Flop.Phoenix.table
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
  - `event` (optional) - If set, `Flop.Phoenix` will render links with a
    `phx-click` attribute.
  - `target` (optional) - Sets the `phx-target` attribute for the header links.
  - `opts` (optional) - Keyword list with additional options (see
    `t:Flop.Phoenix.table_option/0`). Note that the options passed to the
    function are deep merged into the default options. These options will
    likely be the same for all the tables in a project, so it probably makes
    sense to define them once in a function or set them in a wrapper function
    as described in the `Customization` section of the module documentation.

  ## Flop.Schema

  If you pass the `for` option when making the query with Flop, Flop Phoenix can
  determine which table columns are sortable. It also hides the `order` and
  `page_size` parameters if they match the default values defined with
  `Flop.Schema`.

  ## Col slot

  For each column to render, add one `<:col>` element.

  ```elixir
  <:col let={pet} label="Name" field={:name}><%= pet.name %></:col>
  ```

  - `label` - The content for the header column.
  - `field` (optional) - The field name for sorting.
  - `show` (optional) - Boolean value to conditionally show the column. Defaults
    to `true`.
  - `hide` (optional) - Boolean value to conditionally hide the column. Defaults
    to `false`.

  ## Foot slot

  You can optionally add a `foot`. The inner block will be rendered inside
  a `tfoot` element.

      <Flop.Phoenix.table>
        <:foot>
          <tr><td>Total: <span class="total"><%= @total %></span></td></tr>
        </:foot>
      </Flop.Phoenix.table>
  """
  @doc since: "0.6.0"
  @doc section: :components
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
  Renders all inputs for a filter form including the hidden inputs.

  If you need more control, you can use `filter_input/1` and `filter_label/1`
  directly.

  ## Example

      <.form let={f} for={@meta}>
        <.filter_fields let={entry} form={f} fields={[:email, :name]}>
          <%= entry.label %>
          <%= entry.input %>
        </.filter_fields>
      </.form>

  ## Assigns

  - `form` - The `Phoenix.HTML.Form`.
  - `fields` - The list of fields and field options. Note that inputs will not
    be rendered for fields that are not marked as filterable in the schema.
  - `dynamic` (optional) - If `true`, fields are only rendered for filters that
    are present in the `Flop.Meta` struct passed to the form. You can use this
    for rendering filter forms that allow the user to add and remove filters
    dynamically. The `fields` assign is only used for looking up the options
    in that case. Defaults to `false`.
  - `id` (optional) - Overrides the ID for the nested filter inputs.
  - `input_opts` (optional) - Additional options passed to each input.
  - `label_opts` (optional) - Additional options passed to each label.

  ## Inner block

  The generated labels and inputs are passed to the inner block instead of being
  automatically rendered. This allows you to customize the markup.

      <.filter_fields let={e} form={f} fields={[:email, :name]}>
        <div class="field-label"><%= e.label %></div>
        <div class="field-body"><%= e.input %></div>
      </.filter_fields>

  ## Field configuration

  The fields can be passed as atoms or keywords with additional options.

      fields={[:name, :email]}

  Or

      fields={[
        name: [label: gettext("Name")],
        email: [
          label: gettext("Email"),
          op: :ilike_and,
          type: :email_input
        ]
      ]}

  Options:

  - `label`
  - `op`
  - `type`
  - `default`

  The value under the `:type` key matches the format used in `filter_input/1`.
  Any additional options will be passed to the input (e.g. HTML classes).

  ## Label and input opts

  You can set default attributes for all labels and inputs:

      <.filter_fields
        let={e}
        form={f}
        fields={[:name]}
        input_opts={[class: "input"]}
        label_opts={[class: "label"]}
      >

  The additional options in the type configuration are merged into the input
  opts. This means you can set a default class and override it for individual
  fields.

      <.filter_fields
        let={e}
        form={f}
        fields={[
          :name,
          :email,
          role: [type: {:select, ["author", "editor"], class: "select"}]
        ]}
        input_opts={[class: "input"]}
      >
  """
  @doc since: "0.12.0"
  @doc section: :components
  @spec filter_fields(map) :: Phoenix.LiveView.Rendered.t()
  def filter_fields(assigns) do
    is_meta_form!(assigns.form)
    fields = assigns[:fields] || []

    labels =
      fields
      |> Enum.map(fn
        {field, opts} -> {field, opts[:label]}
        field -> {field, nil}
      end)
      |> Enum.reject(fn {_, label} -> is_nil(label) end)

    types =
      fields
      |> Enum.map(fn
        {field, opts} -> {field, opts[:type]}
        field -> {field, nil}
      end)
      |> Enum.reject(fn {_, type} -> is_nil(type) end)

    inputs_for_fields = if assigns[:dynamic], do: nil, else: fields

    assigns =
      assigns
      |> assign(:fields, inputs_for_fields)
      |> assign(:labels, labels)
      |> assign(:types, types)
      |> assign_new(:id, fn -> nil end)
      |> assign_new(:input_opts, fn -> [] end)
      |> assign_new(:label_opts, fn -> [] end)

    ~H"""
    <%= filter_hidden_inputs_for(@form) %>
    <%= for ff <- inputs_for(@form, :filters, fields: @fields, id: @id) do %>
      <%= render_slot(@inner_block, %{
        label: ~H"<.filter_label form={ff} texts={@labels} {@label_opts} />",
        input: ~H"<.filter_input form={ff} types={@types} {@input_opts} />"
      }) %>
    <% end %>
    """
  end

  @doc """
  Renders a label for the `:value` field of a filter.

  This function must be used within the `Phoenix.HTML.Form.inputs_for/2`,
  `Phoenix.HTML.Form.inputs_for/3` or `Phoenix.HTML.Form.inputs_for/4` block of
  the filter form.

  Note that `inputs_for` will not render inputs for fields that are not marked
  as filterable in the schema, even if passed in the options.

  ## Assigns

  - `form` - The filter form.
  - `texts` (optional) - Either a function or a keyword list for setting the
    label text depending on the field.

  All additional assigns will be passed to the label.

  ## Example

      <.form let={f} for={@meta}>
        <%= filter_hidden_inputs_for(f) %>

        <%= for ff <- inputs_for(f, :filters, fields: [:email]) do %>
          <.filter_label form={ff} />
          <.filter_input form={ff} />
        <% end %>
      </.form>

  `Flop.Phoenix.filter_hidden_inputs_for/1` is necessary because
  `Phoenix.HTML.Form.hidden_inputs_for/1` does not support lists in versions
  <= 3.1.0.

  ## Label text

  By default, the label text is inferred from the value of the `:field` key of
  the filter. You can override the default type by passing a keyword list or a
  function that maps fields to label texts.

      <.filter_label form={ff} text={[
        email: gettext("Email")
        phone: gettext("Phone number")
      ]} />

  Or

      <.filter_label form={ff} text={
        fn
          :email -> gettext("Email")
          :phone -> gettext("Phone number")
        end
      } />
  """
  @doc since: "0.12.0"
  @doc section: :components
  @spec filter_label(map) :: Phoenix.LiveView.Rendered.t()
  def filter_label(assigns) do
    is_filter_form!(assigns.form)

    opts = assigns_to_attributes(assigns, [:form, :texts])

    assigns =
      assigns
      |> assign_new(:texts, fn -> nil end)
      |> assign(:opts, opts)

    ~H"""
    <%= label @form, :value, label_text(@form, @texts), opts %>
    """
  end

  defp label_text(form, nil), do: form |> input_value(:field) |> humanize()

  defp label_text(form, func) when is_function(func, 1),
    do: form |> input_value(:field) |> func.()

  defp label_text(form, mapping) when is_list(mapping) do
    field = input_value(form, :field)
    safe_get(mapping, field, label_text(form, nil))
  end

  defp safe_get(keyword, key, default)
       when is_list(keyword) and is_atom(key) do
    Keyword.get(keyword, key, default)
  end

  defp safe_get(keyword, key, default)
       when is_list(keyword) and is_binary(key) do
    value =
      Enum.find(keyword, fn {current_key, _} ->
        Atom.to_string(current_key) == key
      end)

    case value do
      nil -> default
      {_, value} -> value
    end
  end

  @doc """
  Renders an input for the `:value` field and hidden inputs of a filter.

  This function must be used within the `Phoenix.HTML.Form.inputs_for/2`,
  `Phoenix.HTML.Form.inputs_for/3` or `Phoenix.HTML.Form.inputs_for/4` block of
  the filter form.

  ## Assigns

  - `form` - The filter form.
  - `skip_hidden` (optional) - Disables the rendering of the hidden inputs for
    the filter. Default: `false`.
  - `types` (optional) - Either a function or a keyword list that maps fields
    to input types

  All additional assigns will be passed to the input function.

  ## Example

      <.form let={f} for={@meta}>
        <%= filter_hidden_inputs_for(f) %>

        <%= for ff <- inputs_for(f, :filters, fields: [:email]) do %>
          <.filter_label form={ff} />
          <.filter_input form={ff} />
        <% end %>
      </.form>

  ## Types

  By default, the input type is inferred from the field type in the Ecto schema.
  You can override the default type by passing a keyword list or a function that
  maps fields to types.

      <.filter_input form={ff} types={[
        email: :email_input,
        phone: :telephone_input
      ]} />

  Or

      <.filter_input form={ff} types={
        fn
          :email -> :email_input
          :phone -> :telephone_input
        end
      } />

  The type can be given as:

  - An atom referencing the input function from `Phoenix.HTML.Form`:
    `:telephone_input`
  - A tuple with an atom and additional options. The given list is merged into
    the `opts` assign and passed to the input:
    `{:telephone_input, class: "phone"}`
  - A tuple with an atom, options for a select input, and additional options:
    `{:select, ["Option a": "a", "Option B": "b"], class: "select"}`
  - A 3-arity function taking the form, field and opts. This is useful for
    custom input functions:
    `fn form, field, opts -> ... end` or `&my_custom_input/3`
  - A tuple with a 3-arity function and additional opts:
    `{&my_custom_input/3, class: "input"}`
  - A tuple with a 4-arity function, a list of options and additional opts:
    `{fn form, field, options, opts -> ... end, ["Option a": "a", "Option B": "b"], class: "select"}`
  """
  @doc since: "0.12.0"
  @doc section: :components
  @spec filter_input(map) :: Phoenix.LiveView.Rendered.t()
  def filter_input(assigns) do
    is_filter_form!(assigns.form)
    opts = assigns_to_attributes(assigns, [:form, :skip_hidden, :type, :types])

    assigns =
      assigns
      |> assign_new(:skip_hidden, fn -> false end)
      |> assign(:type, type_for(assigns.form, assigns[:types]))
      |> assign(:opts, opts)

    ~H"""
    <%= unless @skip_hidden do %><%= hidden_inputs_for @form %><% end %>
    <%= render_input(@form, @type, @opts) %>
    """
  end

  defp render_input(form, type, opts) when is_atom(type) do
    apply(Phoenix.HTML.Form, type, [form, :value, opts])
  end

  defp render_input(form, {type, input_opts}, opts) when is_atom(type) do
    opts = Keyword.merge(opts, input_opts)
    apply(Phoenix.HTML.Form, type, [form, :value, opts])
  end

  defp render_input(form, {type, options, input_opts}, opts)
       when is_atom(type) and is_list(options) do
    opts = Keyword.merge(opts, input_opts)
    apply(Phoenix.HTML.Form, type, [form, :value, options, opts])
  end

  defp render_input(form, func, opts) when is_function(func, 3) do
    apply(func, [form, :value, opts])
  end

  defp render_input(form, {func, input_opts}, opts) when is_function(func, 3) do
    opts = Keyword.merge(opts, input_opts)
    apply(func, [form, :value, opts])
  end

  defp render_input(form, {func, options, input_opts}, opts)
       when is_function(func, 4) and is_list(options) do
    opts = Keyword.merge(opts, input_opts)
    apply(func, [form, :value, options, opts])
  end

  defp type_for(form, nil), do: input_type(form, :value)

  defp type_for(form, func) when is_function(func, 1) do
    form |> input_value(:field) |> func.()
  end

  defp type_for(form, mapping) when is_list(mapping) do
    field = input_value(form, :field)
    safe_get(mapping, field, type_for(form, nil))
  end

  defp is_filter_form!(%Form{data: %Filter{}, source: %Meta{}}), do: :ok

  defp is_filter_form!(_) do
    raise ArgumentError, """
    must be used with a filter form

    Example:

        <.form let={f} for={@meta}>
          <%= filter_hidden_inputs_for(f) %>

          <%= for ff <- inputs_for(f, :filters, fields: [:email]) do %>
            <.filter_label form={ff} />
            <.filter_input form={ff} />
          <% end %>
        </.form>
    """
  end

  defp is_meta_form!(%Form{data: %Flop{}, source: %Meta{}}), do: :ok

  defp is_meta_form!(_) do
    raise ArgumentError, """
    must be used with a filter form

    Example:

        <.form let={f} for={@meta}>
          <.filter_fields let={entry} form={f} fields={[:email, :name]}>
            <%= entry.label %>
            <%= entry.input %>
          </.filter_fields>
        </.form>
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

    default_limit = Flop.get_option(:default_limit, opts)
    default_order = Flop.get_option(:default_order, opts)

    []
    |> Misc.maybe_put(:offset, flop.offset, 0)
    |> Misc.maybe_put(:page, flop.page, 1)
    |> Misc.maybe_put(:after, flop.after)
    |> Misc.maybe_put(:before, flop.before)
    |> Misc.maybe_put(:page_size, flop.page_size, default_limit)
    |> Misc.maybe_put(:limit, flop.limit, default_limit)
    |> Misc.maybe_put(:first, flop.first, default_limit)
    |> Misc.maybe_put(:last, flop.last, default_limit)
    |> Misc.maybe_put_order_params(flop, default_order)
    |> Misc.maybe_put(:filters, filter_map)
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

  @doc """
  Generates hidden inputs for the given form.

  This does the same as `Phoenix.HTML.Form.hidden_inputs_for/1` in versions
  <= 3.1.0, except that it supports list fields. If you use a later
  `Phoenix.HTML` version, you don't need this function.
  """
  @doc since: "0.12.0"
  @doc section: :components
  @spec filter_hidden_inputs_for(Phoenix.HTML.Form.t()) ::
          list(Phoenix.HTML.safe())
  def filter_hidden_inputs_for(form) do
    Enum.flat_map(form.hidden, fn {k, v} ->
      filter_hidden_inputs_for(form, k, v)
    end)
  end

  defp filter_hidden_inputs_for(form, k, values) when is_list(values) do
    id = input_id(form, k)
    name = input_name(form, k)

    for {v, index} <- Enum.with_index(values) do
      hidden_input(form, k,
        id: id <> "_" <> Integer.to_string(index),
        name: name <> "[]",
        value: v
      )
    end
  end

  defp filter_hidden_inputs_for(form, k, v) do
    [hidden_input(form, k, value: v)]
  end
end
