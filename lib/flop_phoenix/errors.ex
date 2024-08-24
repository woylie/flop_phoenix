defmodule Flop.Phoenix.InvalidFilterFieldConfigError do
  @moduledoc """
  Raised when the `fields` attribute of the `Flop.Phoenix.filter_fields`
  component is set to an invalid value.
  """
  defexception [:value]

  def message(%{value: value}) do
    """
    Invalid filter field config

    An invalid value was passed to the `:fields` attribute.

    Filters fields must be passed as a list of atoms or {atom, keyword} tuples.

    Got:

        #{inspect(value, pretty: true, width: 76)}

    Expected a list of atoms:

        fields={[:name, :age]}

    Or a keyword list with additional options:

        fields={[
          name: [label: "Name"]
          age: [label: "Minimum age", type: "number", operator: ">="]
        ]}
    """
  end
end

defmodule Flop.Phoenix.NoMetaFormError do
  @moduledoc """
  Raised when a `Phoenix.HTML.Form` struct is passed to
  `Flop.Phoenix.filter_fields/1` that was not built with `Flop.Meta` struct.
  """
  defexception []

  def message(_) do
    """
    Not a Flop.Meta form

    The `form` attribute for the `Flop.Phoenix.filter_fields` component must
    be a `Phoenix.HTML.Form` that has a `Flop.Meta` struct as its source.

    Example:

        def filter_form(%{meta: meta} = assigns) do
          assigns = assign(assigns, :form, Phoenix.Component.to_form(meta))

          ~H\"""
          <.form for={@form}>
            <.filter_fields :let={i} form={@form} fields={[:email, :name]}>
              <.input
                field={i.field}
                label={i.label}
                type={i.type}
                {i.rest}
              />
            </.filter_fields>
          </.form>
          \"""
        end
    """
  end
end

defmodule Flop.Phoenix.PathOrJSError do
  @moduledoc """
  Raised when a neither the `path` nor the `on_*` attribute is set for a
  pagination or table component.
  """
  defexception [:component]

  def message(%{component: component}) do
    """
    path or #{on_attribute(component)} attribute is required

    At least one of the mentioned attributes is required for the #{component}
    component. Combining them will both patch the URL and execute the
    JS command.

    The :path value can be a path as a string, a {module, function_name, args}
    tuple, a {function, args} tuple, or an 1-ary function.

    Examples:

        path={~p"/pets"}
        path={{Routes, :pet_path, [@socket, :index]}}
        path={{&Routes.pet_path/3, [@socket, :index]}}
        path={&build_path/1}

        #{on_examples(component)}
    """
  end

  defp on_attribute(:table), do: "on_sort"
  defp on_attribute(_), do: "on_paginate"

  defp on_examples(:table), do: "on_sort={JS.push(\"sort-table\")}"
  defp on_examples(_), do: "on_paginate={JS.push(\"paginate\")}"
end

defmodule Flop.Phoenix.IncorrectPaginationTypeError do
  @moduledoc """
  Raised when the pagination type used for a query is not supported by a
  component.
  """
  defexception [:component]

  def message(%{component: _component}) do
    """
    Pagination type not supported by component

    - For page-based pagination, use `Flop.Phoenix.pagination/1`.
    - For cursor-based pagination, use `Flop.Phoenix.cursor_pagination/1`.
    """
  end
end
