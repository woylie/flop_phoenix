# Changelog

## Unreleased

### Added

- Accept global attributes for pagination component.
- Add `ellipsis` slot to pagination component.

### Changed

- Use `<button>` elements for pagination if no `path` is set.
- Add `rel` attribute to previous/next links.
- Mark up disabled previous/next links of the pagination as
  `<a role="link" aria-disabled="true">` instead of `<span>`.
- Update documentation for `hidden_inputs_for_filter/1` to use
  `Phoenix.Component.inputs_for/1` with the `skip_persistent_id` option.
- Require Phoenix >= 1.6.0 and < 1.9.0.

### Removed

- Remove `wrapper_attrs` from the pagination options. Pass the attributes
  directly as attributes instead.
- Remove default `class` attributes from pagination component.
- Remove `role` attribute from the pagination component. The `<nav>` element
  already has the implicit ARIA role `navigation`.
- Remove `ellipsis_attrs` and `ellipsis_content` from the pagination options.
  Use the `ellipsis` slot instead.
- Remove `current_link_attrs` from pagination options. Use
  `[aria-current="page"]` CSS selector instead.
- Remove `disabled_attrs` from pagination options. Use `[aria-disabled="true"]`
  CSS selector instead.

### How to upgrade

Remove the `wrapper_opts` from your pagination options and pass them directly
as attributes instead.

```diff
  <Flop.Phoenix.pagination
    meta={@meta}
    path={@path}
    opts={[
-     wrapper_attrs: [
-       class: "pagination",
-       aria: [label: "Quppernerit"]
-     ]
    ]}
+   class="pagination"
+   aria-label="Quppernerit"
  />
```

Replace the `:ellipsis_attrs` and `:ellipsis_content` attributes with the
`ellipsis` slot.

```diff
  <Flop.Phoenix.pagination
    meta={@meta}
    path={@path}
    opts={[
-     ellipsis_attrs: [class: "ellipsis", aria-hidden: "true"],
-     elipsis_content: "‥"
    ]}
- />
+ >
+   <:ellipsis>
+     <span class="ellipsis" aria-hidden="true">‥</span>
+   </:ellipsis>
+ </Flop.Phoenix.pagination>
```

Remove the `:disabled_attrs` option. Select disabled links in CSS with
`a:[aria-disabled="true"]`.

```diff
  <Flop.Phoenix.pagination
    meta={@meta}
    path={@path}
    opts={[
-     disabled_attrs: [class: "is-disabled"],
    ]}
  >
```

## [0.24.0] - 2025-02-01

### Added

- Add `Flop.Phoenix.Pagination` struct to hold information needed to render
  a pagination component.
- Add `Flop.Phoenix.Pagination.new/2` to build a `Pagination` struct from a
  `Flop.Meta` struct.
- Add `Flop.Phoenix.pagination_for/1` for building custom pagination components.
  Update the existing `Flop.Phoenix.pagination/1` component to use it.
- Add `Flop.Phoenix.page_link_range/3` for determining which page links to
  render in a pagination component.

### Changed

- Support cursor pagination in `Flop.Phoenix.pagination/1`.
- Remove the `page_links` option from the `pagination_opts`. Set this option
  with the new `page_links` attribute instead.
- Change the values of the `page_links` option from
  `:all | :hide | {:ellipsis, pos_integer}` to `:all | :none | pos_integer`.
- Change default value for `page_links` option of the
  `Flop.Phoenix.pagination/1` component from `:all` to `5`.
- Deprecate configuring the `pagination` and `table` components via the
  application environment. Define wrapper components that pass the `opts`
  attribute to the Flop.Phoenix components instead.
- Remove dependency on PhoenixHTMLHelpers.
- Require Phoenix LiveView ~> 1.0.0.
- Require Elixir ~> 1.14.

### Removed

- Remove `Flop.Phoenix.cursor_pagination/1`. Use `Flop.Phoenix.pagination/1`
  instead.
- Remove `t:Flop.Phoenix.cursor_pagination_option/0`.
- Remove `Flop.Phoenix.IncorrectPaginationTypeError`.
- Remove `input_type/3` from the `Phoenix.HTML.FormData` protocol
  implementation for `Flop.Meta`. The function had been removed from the
  protocol in Phoenix.HTML 4.0.
- Remove the previously deprecated `event` attribute from the
  `Flop.Phoenix.pagination/1` and `Flop.Phoenix.table/1` components. Use
  `:on_paginate` and `:on_sort` instead.
- Remove the previously deprecated `hide` and `show` attributes from the
  `:col` and `:action` slots of the `Flop.Phoenix.table/1` component. Use the
  `:if` attribute instead.

### Fixed

- Fix a warning about ranges in Elixir 1.18.

### How to upgrade

Replace `Flop.Phoenix.cursor_pagination/1` with `Flop.Phoenix.pagination/1`.

```diff
- <Flop.Phoenix.cursor_pagination meta={@meta} path={~p"/pets"} />
+ <Flop.Phoenix.pagination meta={@meta} path={~p"/pets"} />
```

Update the format of the `page_links` option for the pagination component.

```diff
- page_links: {:ellipsis, 7},
+ page_links: 7,

- page_links: :hide,
+ page_links: :none,
```

Remove `page_links` from your `pagination_opts` function and add it as an
attribute instead.

```diff
def pagination_opts do
  [
    ellipsis_attrs: [class: "ellipsis"],
    ellipsis_content: "‥",
    next_link_attrs: [class: "next"],
    next_link_content: next_icon(),
-     page_links: 7,
    pagination_link_aria_label: &"#{&1}ページ目へ",
    previous_link_attrs: [class: "prev"],
    previous_link_content: previous_icon()
  ]
end

<Flop.Phoenix.pagination
  meta={@meta}
  path={~p"/pets"}
+ page_links={7}
/>
```

Replace the `:show` and `:hide` attribute in the `:col` slot of the table
component with `:if`.

```diff
<:col
  :let={pet}
- show={@admin?}
+ :if={@admin?}
  label="Name"
  field={:name}
>
  <%= pet.name %>
</:col>

<:col
  :let={pet}
- hide={!@admin?}
+ :if={@admin?}
  label="Name"
  field={:name}
>
  <%= pet.name %>
</:col>
```

Replace the `event` attribute of the pagination table components with
`on_paginate` and `on_sort`.

```diff
<Flop.Phoenix.pagination
  meta={@meta}
- event="paginate"
+ on_paginate={JS.push("paginate")}
/>

<Flop.Phoenix.table
  items={@pets}
  meta={@meta}
- event="sort"
+ on_sort={JS.push("sort")}
>
```

Remove the configuration for the pagination component from `config/config.exs`
and define a wrapper component in your `CoreComponents` module instead. This
is optional, but will make future version updates easier.

For the pagination component:

```diff
# config/config.exs

config :flop_phoenix,
- pagination: [opts: {MyAppWeb.CoreComponents, :pagination_opts}],
  table: [opts: {MyAppWeb.CoreComponents, :table_opts}]

# MyAppWeb.CoreComponents

- def pagination_opts do
-   [
-     # ...
-   ]
- end

+ attr :meta, Flop.Meta, required: true
+ attr :path, :any, default: nil
+ attr :on_paginate, JS, default: nil
+ attr :target, :string, default: nil
+
+ def pagination(assigns) do
+   ~H\"""
+   <Flop.Phoenix.pagination
+     meta={@meta}
+     path={@path}
+     on_paginate={@on_paginate}
+     target={@target}
+     opts={[
+       # ...
+     ]}
+   />
+   \"""
+ end
```

## [0.23.1] - 2024-10-17

### Changed

- Raise an error if a meta struct with the wrong pagination type is passed to
  the `pagination` or `cursor_pagination` component.

### Fixed

- Fix compilation error in Phoenix LiveView 1.0.0-rc.7.
- Fix type of `row_click` attribute.

## [0.23.0] - 2024-08-18

### Changed

- Support and require `live_view ~> 1.0.0-rc.0`.
- Allow to pass options directly in config file instead of referencing function.

### Fixed

- Fixed a deprecation warning in Elixir 1.17.

## [0.22.10] - 2024-08-18

### Changed

- Loosen version requirement for `flop` to support 0.26.

## [0.22.9] - 2024-05-04

### Added

- Added `:pagination_list_item_attrs` option to `Flop.Phoenix.pagination/1`.

## [0.22.8] - 2024-03-23

### Added

- Support `:col_class` attr on `:col` and `:action` slots in addition to
  `:col_style`.

### Changed

- Don't render empty `style` attributes on `col` elements in `colgroup`.

### Fixed

- The page range calculation in the `Flop.Phoenix.pagination/1` was incorrect
  towards the last pages.

## [0.22.7] - 2024-03-02

### Changed

- Loosen version requirement for `phoenix_html`.

### Fixed

- Warning when wrapping table component and passing on `:col` slot as attribute.

## [0.22.6] - 2024-01-14

### Changed

- Support Flop 0.25.0.
- Update documentation examples for filter forms.

## [0.22.5] - 2023-12-24

### Changed

- Requires `phoenix_html ~> 4.0`.

## [0.22.4] - 2023-11-18

### Fixed

- Don't render `li` element if a pagination link is not rendered.

## [0.22.3] - 2023-11-14

### Changed

- Support Flop ~> 0.24.0.

## [0.22.2] - 2023-10-19

### Fixed

- Numbered pagination links were not wrapped in `li` elements.

## [0.22.1] - 2023-09-28

### Changed

- Allow to use `t:Phoenix.HTML.safe/0` as a label attribute in table headers.

## [0.22.0] - 2023-09-26

### Added

- Added `directions` attribute to the `col` slot of the table component. This
  allows you to override the default sort directions, e.g. to specify
  nulls-first or nulls-last.
- Added `thead_th_attrs` and `th_wrapper_attrs` attributes to the `col` slot
  of the table component.
- Added `thead_th_attrs` attribute to the `action` slot of the table component.

### Changed

- Renamed `attrs` attribute on the `col` and `action` slots of the table
  component to `tbody_td_attrs` in order to match the naming of the global
  table options.

### How to upgrade

Rename the `attrs` attribute to `tbody_td_attrs` in both the `col` slot and the
`action` slot:

```diff
<Flop.Phoenix.table items={@pets} meta={@meta} path={~p"/pets"}>
-  <:col :let={p} attrs={[class="my-class"]}><%= p.id %></:col>
-  <:action :let={p} attrs={[class="my-class"]}>button</:col>
+  <:col :let={p} tbody_td_attrs={[class="my-class"]}><%= p.id %></:col>
+  <:action :let={p} tbody_td_attrs={[class="my-class"]}>button</:col>
</Flop.Phoenix.table>
```

## [0.21.2] - 2023-09-26

### Changed

- Support `phoenix_liveview ~> 0.20`.

## [0.21.1] - 2023-08-05

### Added

- Allow passing a function to the `attrs` option of table component's `:action`
  slot. Before, this was only supported in the `:col` slot.

### Changed

- Improve some error messages and documentation examples.

### Fixed

- In the `:col` and `:action` slots of the table component, the `attrs` option
  did not properly override the attributes set with the `:tbody_td_attrs`
  option.

## [0.21.0] - 2023-07-17

### Changed

- Depend on flop ~> 0.22.0.

## [0.20.0] - 2023-07-09

### Added

- Added an `on_paginate` attribute to the `pagination` and `cursor_pagination`
  components. This attribute takes a `Phoenix.LiveView.JS` command as a value.
  The attribute can be combined with the `path` attribute, in which case the URL
  will be patched _and_ the the given JS command is executed.
- Similarly, an `on_sort` attribute was added to the `table` component.
- Allow setting `tbody_tr_attrs` to a function that takes the current row item
  as an argument and returns a list of attributes.
- Allow setting the `attrs` attribute of the `:col` slot of the table component
  to a function that takes the current row item as an argument and returns a
  list of attributes.

### Changed

- The table ID falls back to `"sortable-table"` if no schema module is used.
- The tbody ID was changed to `{id}-tbody`.
- The table container ID is set to `{id}-container` now.
- The table ID is set to `{id}` now.

### Deprecated

- The `show` and `hide` attributes of the `:col` slot of the table component are
  now deprecated in favor of the `:if` attribute.
- The `event` attribute of the pagination, cursor pagination and table
  components has been deprecated in favor of `on_pagination` and `on_sort`.

## [0.19.1] - 2023-06-30

### Changed

- The table component only renders an ascending/descending order indicator in
  the column header for the first order field, instead rendering one in the
  column headers for all ordered fields.
- Support Flop 0.22.

## [0.19.0] - 2023-05-30

### Changed

- Necessary updates for `phoenix_live_view ~> 0.19.0`.
- Requires `phoenix_live_view ~> 0.19.0`.
- Remove previously deprecated `Flop.Phoenix.pop_filter/2`. Use
  `Flop.Filter.pop/3` instead.

## [0.18.2] - 2023-05-08

### Changed

- Added `hidden` attribute to hidden inputs rendered by `filter_fields`
  component in order to solve CSS spacing issues.

## [0.18.1] - 2023-03-18

### Changed

- Added support for LiveView streams to the table component. To this end,
  `row_id`, `row_item` and `id` attributes were added to the component,
  following the example of Phoenix 1.7. The `id` attribute is added to the
  `tbody`. If no `id` is explicitly set, a default value will be used depending
  on the schema name.

## [0.18.0] - 2023-02-25

### Changed

- Added dependency on `Phoenix.HTML` `~> 3.3.0`.
- The `filter_fields` component now passes the `Phoenix.HTML.FormField` struct
  introduced in `Phoenix.HTML` 3.3.0 to the inner block.
- Support `:as` option for filter inputs with `Phoenix.HTML.FormData/4`
  (`inputs_for`).
- `Phoenix.HTML.FormData.input_type/2` now considers the Ecto type for join,
  custom and compound fields.
- Remove support for `path_helper` assigns, previously deprecated in 0.15.
- Deprecate `Flop.Phoenix.pop_filter/2`.

### How to upgrade

If your `input` component already knows how to handle the
`Phoenix.HTML.FormField` struct, you can update the inner block for
`filter_fields` like this:

```diff
<.filter_fields :let={i} form={f} fields={[:email, :name]}>
  <.input
-    field={{i.form, i.field}}
+    field={i.field}
    type={i.type}
    label={i.label}
-    id={i.id}
-    name={i.name}
-    value={i.value}
    {i.rest}
  />
</.filter_fields>
```

If your `input` component still expects the individual assigns, you can update
the inner block like this:

```diff
<.filter_fields :let={i} form={f} fields={[:email, :name]}>
  <.input
-    field={{i.form, i.field}}
+    field={{i.field.form, i.field.field}}
    type={i.type}
    label={i.label}
-    id={i.id}
-    name={i.name}
-    value={i.value}
+    id={i.field.id}
+    name={i.field.name}
+    value={i.field.value}
    {i.rest}
  />
</.filter_fields>
```

For an upgrade example for the `path_helper` assign, see the changelog entry for
version 0.15.0.

## [0.17.2] - 2023-01-15

### Changed

- Support Flop 0.19.

## [0.17.1] - 2022-11-15

### Added

- Allow passing an `offset` when generating filter inputs with
  `Phoenix.HTML.Form.inputs_for/3`.

## [0.17.0] - 2022-10-27

### Added

- New option `tbody_attrs` for table component.
- New attribute `row_click` and slot `action` for table component.

### Changed

- To pass additional attributes to a column, you will now have to use the
  `attrs` attribute. This was necessary because defining a `global` attribute on
  a slot causes a compile-time error in `phoenix_live_view` 0.18.3.

```diff
<Flop.Phoenix.table items={@pets} meta={@meta} path={~p"/pets"}>
-  <:col :let={p} class="my-class"><%= p.id %></:col>
+  <:col :let={p} attrs={[class="my-class"]}><%= p.id %></:col>
</Flop.Phoenix.table>
```

## [0.16.0] - 2022-10-10

### Added

- New Phoenix component `Flop.Phoenix.hidden_inputs_for_filter/1`.

### Changed

- Major refactoring of `Flop.Phoenix.filter_fields/1`. Instead of giving you the
  rendered `<label>` and `<input>` elements, the component now only passes the
  necessary arguments to the inner block. You will have to pass these arguments
  to your own `input` component (or whatever you name it). The field option
  format has also been updated. These changes were made to fix warnings emitted
  by live view 0.18.1, and also accompany current changes in Phoenix that thin
  out `Phoenix.HTML` / `Phoenix.HTML.Form` in favor of Phoenix components for
  inputs.
- Require `flop >= 0.17.1 and < 0.19.0`.

### Removed

- Removed `Flop.Phoenix.filter_hidden_inputs_for/1`. This function is not used
  internally anymore. You can either use `Phoenix.HTML.Form.hidden_inputs_for/1`
  (Phoenix.HTML ~> 3.2), or use `Flop.Phoenix.hidden_inputs_for_filter/1`,
  which does the same, but as a Phoenix component.
- Removed `Flop.Phoenix.filter_label/1` and `Flop.Phoenix.filter_input/1`. With
  the changes to `Flop.Phoenix.filter_fields/1` and the move away from the
  input rendering functions of `Phoenix.HTML.Form`, these functions don't have
  any value anymore. Read the documentation of
  `Flop.Phoenix.hidden_inputs_for_filter/1` for an example on how to easily
  render the fields of individual filters.

### Fixed

- Fixed warnings about tainted variables in live view 0.18.1.
- Fixed an issue where default parameters set in the backend module were not
  removed from the query parameters.
- Fixed URLs ending with `?` when no query parameters are necessary if the path
  is passed as a string.

### How to upgrade

#### Filter fields component

Previously, you would render a filter form like this:

```elixir
<.form :let={f} for={@meta}>
  <Flop.Phoenix.filter_fields :let={entry} form={f} fields={[:name, :email]}>
    <div class="field">
      <%= entry.label %>
      <%= entry.input %>
    </div>
  </Flop.Phoenix.filter_fields>
</.form>
```

In this example, `entry.label` and `entry.input` are complete `<label>` and
`<input>` elements with all attributes set. You will need to change this to:

```elixir
<.form :let={f} for={@meta}>
  <.filter_fields :let={i} form={f} fields={[:name, :email]}>
    <.input
      id={i.id}
      name={i.name}
      label={i.label}
      type={i.type}
      value={i.value}
      field={{i.form, i.field}}
      {i.rest}
    />
  </.filter_fields>
</.form>
```

You will have to define an `input` component in your project. You can take a
hint from the `input` component that is generated as part of the [Components
module](https://github.com/phoenixframework/phoenix/blob/master/priv/templates/phx.gen.live/components.ex) by Phoenix 1.7.

#### Field options

Remove `input_opts` and `label_opts` and pass them directly to your `input`
component, or add them directly to the `input` component. If you passed an `id`
to `filter_fields`, set in on the `form` instead.

```diff
<.filter_fields
  :let={i}
  form={f}
  fields={[:name]}
-  id="some-id"
-  input_opts={[class: "input", phx_debounce: 100]}
-  label_opts={[class: "label"]}
>
  <.input
     ...
+    class="input"
+    phx-debounce={100}
  />
</.filter_fields>
```

Use strings instead of atoms to set the type, and use the types that your
`input` component understands.

```diff
<.filter_fields
  :let={i}
  form={f}
  fields={[
-    name: [type: :text_input],
+    name: [type: "text"],
-    age: [type: :number_input],
+    age: [type: "number"],
-    phone: [type: :telephone_input],
+    phone: [type: "tel"]
  ]}
>
```

If you passed additional input function options in a tuple, take them out of
the tuple and add them to the keyword list instead.

```diff
<.filter_fields
  :let={i}
  form={f}
  fields={[
-    role: [type: {:select, ["author", "editor"], class: "select"}]
+    role: [type: "select", options: ["author", "editor"], class: "select"]
  ]}
>
```

The `default` option is not handled for you anymore. You can still set it, but
it will just be passed on as part of the `rest` options, so your `input`
component will need to handle it.

#### Filter label and input components

If you used `Flop.Phoenix.filter_label/1` or `Flop.Phoenix.filter_input/1`
before, follow the example in the documentation of
`Flop.hidden_inputs_for_filter/1` to render the inputs of individual filters
without the removed components.

## [0.15.2] - 2022-10-10

### Changed

- Change version requirement for Flop to `>= 0.15.0 and < 0.19.0`.

## [0.15.1] - 2022-09-30

### Fixed

- Typespec of `Flop.Phoenix.build_path/3`.

## [0.15.0] - 2022-09-22

### Added

This release adds support for passing URI strings instead of MFA or FA tuples to
components and helper functions. This allows you to use the library with the
verified routes introduced in Phoenix 1.7. Alternatively, you can now also
choose to pass a 1-ary path builder function. See `Flop.Phoenix.build_path/3`
for examples. Passing tuples pointing to route helpers is still supported.

- Added an example for a custom filter form component to the readme.
- Support passing a URI string as a path to the `table`, `pagination` and
  `cursor_pagination` components and to `build_path/3`.
- Support passing a 1-ary path builder function to the `table`, `pagination` and
  `cursor_pagination` components and to `build_path/3`.
- New function `Flop.Phoenix.pop_filter/2`.

### Changed

- Require `live_view ~> 0.18.0`.
- Deprecate `path_helper` assign in favor of `path`.
- Use declarative assigns and replace `Phoenix.LiveView.Helpers.live_patch/1`
  with `Phoenix.Component.link/1`.
- `Flop.Phoenix.filter_input/1` requires additional options for the input
  function to be passed in the `input_opts` assign, instead of passing them
  directly to the component. This was necessary because the global attributes
  you can define with declarative assigns in LiveView 0.18 are meant for HTML
  attributes, while the input options may contain any additional attributes
  necessary (e.g. a list of select options that are rendered as option
  elements).

### Fixed

- Apply `show` and `hide` attribute for columns to `colgroup` as well.
- Correctly handle multiple inputs for the same field in `Flop.filter_fields/1`.

### How to upgrade

Rename the `path_helper` assigns of `table`, `pagination` and
`cursor_pagination` components to `path`.

```diff
- <.pagination meta={@meta} path_helper={{Routes, :pet_path, [@socket, :index]}} />
+ <.pagination meta={@meta} path={{Routes, :pet_path, [@socket, :index]}} />
```

Wrap additional options passed to `Flop.Phoenix.filter_input/1` into a single
`input_opts` assign.

```diff
- <.filter_input form={ff} class="select" options={[:some, :options]} />
+ <.filter_input form={ff} input_opts={[class: "select", options: [:some, :options]]} />
```

## [0.14.2] - 2022-08-26

### Changed

- Support Flop `~> 0.17.0`.

## [0.14.1] - 2022-03-22

### Changed

- Support Flop `~> 0.16.0`.

## [0.14.0] - 2022-02-22

### Added

- `symbol_unsorted` option for the `table` component.
- `caption` assign for the `table` component.
- `col_style` assign for the `:col` slot of the `table` component.

### Changed

- Additional attributes passed to the `<:col>` slot will now be added as
  attributes to the `<td>` tags.

## [0.13.0] - 2021-11-14

### Added

- Add `cursor_pagination/1` component.

### Changed

- The pagination component adds the `disabled` class to the `span` that is
  displayed when the previous or next link is disabled now. Previously, the
  `disabled` attribute was set on the `span`. The class can be customized with
  the `:disabled_class` option.

## [0.12.0] - 2021-11-08

### Added

- Implement the `Phoenix.HTML.FormData` protocol for `Flop.Meta`. This means
  you can pass the meta struct as `:for` option to the Phoenix `form_for`
  functions now.
- Add the functions `filter_fields/1`, `filter_input/1` and `filter_label/1`.

### Changed

- Remove `:for` option. The schema module is now automatically derived from the
  meta struct.

## [0.11.1] - 2021-10-31

### Added

- Adds `hide` and `show` options to table `:col`.

### Changed

- Passing a `label` to a table `:col` is now optional.

## [0.11.0] - 2021-10-30

### Changed

- The `path_helper_args` assign has been removed in favor of passing mfa
  tuples as `path_helper`.
- In the same vein, `Flop.Phoenix.build_path/4` has been replaced with
  `Flop.Phoenix.build_path/3`, which also takes a tuple as the first argument.
- The table component has been changed to use slots. The `headers`,
  `footer`, `row_func` and `row_opts` assigns have been removed. Also, the
  `tfoot_td_attrs` and `tfoot_th_attrs` options have been removed.
- The `live_view` version requirement has been changed to `~> 0.17.0`.
- Better error messages for invalid assigns have been added.

### How to upgrade

Update the `path_helper` and `path_helper_args` assigns set for the `table`
and `pagination` component:

```diff
- path_helper={&Routes.pet_path/3}
- path_helper_args={[@socket, :index]}
+ path_helper={{Routes, :pet_path, [@socket, :index]}}
```

If you prefer, you can pass a function instead.

```diff
+ path_helper={{&Routes.pet_path/3, [@socket, :index]}}
```

Update any calls to `Flop.Phoenix.build_path/4`:

```diff
- Flop.Phoenix.build_path(&Routes.pet_path/3, [@socket, :index], meta)
+ Flop.Phoenix.build_path({Routes, :pet_path, [@socket, :index]}, meta)
```

If you prefer, you can use a 2-tuple here as well:

```diff
+ Flop.Phoenix.build_path({&Routes.pet_path/3, [@socket, :index]}, meta)
```

Finally, update the tables in your templates:

```diff
<Flop.Phoenix.table
  for={MyApp.Pet}
  items={@pets}
  meta={@meta}
-   path_helper={&Routes.pet_path/3}
-   path_helper_args={[@socket, :index]}
+   path_helper={{Routes, :pet_path, [@socket, :index]}}
-   headers={[{"Name", :name}, {"Age", :age}]}
-   row_func={fn pet, \_opts -> [pet.name, pet.age] end}
-   footer={["", @average_age]}
- />
+ >
+   <:col let={pet} label="Name" field={:name}><%= pet.name %></:col>
+   <:col let={pet} label="Age" field={:age}><%= pet.age %></:col>

+   <:foot>
+     <tr>
+       <td></td>
+       <td><%= @average_age %></td>
+     </tr>
+   </:foot>
+ </Flop.Phoenix.table>
```

Also, you can remove `tfoot_td_attrs` and `tfoot_th_attrs` from the `opts`
assign (or opts provider function).

## [0.10.0] - 2021-10-24

### Added

- It is now possible to set global options for the components in your config.

```elixir
config :flop_phoenix,
  pagination: [opts: {MyApp.ViewHelpers, :pagination_opts}],
  table: [opts: {MyApp.ViewHelpers, :table_opts}]
```

### Changed

- The `for`, `event` and `target` options moved from the `opts` assign to the
  root. The `opts` assign is now exclusively used for customization options
  that modify the appearance, which are usually set globally for a
  project and are not related to the specific data or view.
- The `row_func/2` function passed to the `table` component receives the new
  `row_opts` assign now instead of the `opts` assign.
- The pagination and table components only pass the `for` option to the query
  builder, instead of all `opts`.
- The `path_helper` and `path_helper_args` assigns are now optional if an
  `event` is passed. A descriptive error is raised if neither of them are
  passed.
- The `opts` assign for the pagination and table components is now optional.
- Aria labels were added to the links to the first and last page.
- The `aria-sort` attribute was added to the table headers.

### How to upgrade

1. Remove the `for`, `event` and `target` from the `opts` assign and add them
   as regular assigns at the root level.
2. Move any key/value pairs that are needed by your `row_func` from `opts` to
   `row_opts`.

For example, if your `row_func` looks like this:

```elixir
def table_row(%Pet{id: id, name: name}, opts) do
  socket = Keyword.fetch!(opts, :socket)
  [name, link("show", to: Routes.pet_path(socket, :show, id))]
end
```

Update your template like this:

```diff
<Flop.Phoenix.sortable_table
  row_func={&table_row/2}
-   opts={[
-     container: true,
-     for: Pet,
-     event: "sort-table",
-     target: @myself,
-     socket: @socket
-   ]}
+   row_opts={[socket: @socket]}
+   for={Pet}
+   event="sort-table"
+   target={@myself}
+   opts={[container: true]}
/>

<Flop.Phoenix.pagination
-   opts={[
-     for: Pet,
-     event: "paginate",
-     target: @myself,
-     page_links: {:ellipsis, 7}
-   ]}
+   for={Pet}
+   event="paginate"
+   target={@myself}
+   opts={[page_links: {:ellipsis, 7}]}
/>
```

## [0.9.1] - 2021-10-22

### Changed

- Change `live_view` version requirement to `~> 0.16.0 or ~> 0.17.0`.

## [0.9.0] - 2021-10-04

### Added

- Add table foot option for sortable table.

## [0.8.1] - 2021-08-11

### Changed

- Loosen version requirement for Flop.

## [0.8.0] - 2021-08-11

### Added

- New options `event` and `target` for the pagination and sortable table
  component, which allow to emit pagination and sorting events in LiveView
  without patching the URL.

### Changed

- Use `HEEx` templates for both the pagination and the sortable table component.
  Refer to the Readme for usage examples.
- Require `live_view ~> 0.16.0`.
- Support safe HTML tuples in unsortable table headers.
- Improve documentation with examples for LiveView, HEEx templates and EEx
  templates.

## [0.7.0] - 2021-06-13

### Added

- Add wrapper around sortable table header link and order direction indicator.
- Add option `current_link_attrs` to pagination builder.
- Add options `thead_tr_attrs`, `thead_th_attrs`, `tbody_tr_attrs` and
  `tbody_td_attrs` to table generator.
- Add option `no_results_content` to table generator, which sets the content
  that is going to be displayed instead of the table if the item list is empty.
  A default option is applied, so make sure to set the option and/or remove your
  own no results messages from your templates when making the upgrade.

### Changed

- The table options `table_class`, `th_wrapper_class`, `symbol_class` and
  `container_class` were replaced in favour of `table_attrs`,
  `th_wrapper_attrs`, `symbol_attrs` and `container_attrs` for more flexibility
  and consistency with the pagination generator. To update, rename the options
  in your code and wrap the values in keyword lists with a `class` key
  (e.g. `container_class: "table-container"` =>
  `container_attrs: [class: "table-container"]`).
- The `pagination_link_attrs` is not applied to current links anymore. Use
  `current_link_attrs` to set the attributes for the current link.
- Omit `page=1` and `offset=0` when building query parameters.
- Omit default values for order and limit/page size parameters when building
  query parameters.
- Requires Flop `~> 0.11.0`.

### Fixed

- Order direction indicator was wrapped twice.
- A Flop struct with an offset was resulting in invalid pagination links.

## [0.6.1] - 2021-05-05

### Fixed

- Pagination helper generated invalid links when using `default_limit` option.

## [0.6.0] - 2021-05-04

### Added

- Add `Flop.Phoenix.table/1` for rendering sortable tables.
- Add function `Flop.Phoenix.to_query/1`, which converts a Flop struct into
  a keyword list for query parameters.
- Add function `Flop.Phoenix.build_path/3`, which applies Flop parameters to a
  Phoenix path helper function.

### Removed

- Remove `Flop.Phoenix.Live.PaginationComponent` in favor of making
  `Flop.Phoenix.pagination/4` work in both `.eex` and `.leex` templates.

## [0.5.1] - 2021-04-14

### Fixed

- Merge pagination query parameters into existing query parameters, if present.

## [0.5.0] - 2021-03-23

### Changed

- Rename `FlopPhoenix` to `Flop.Phoenix`.
- Add `Flop.Phoenix.Live.PaginationComponent` for use with `Phoenix.LiveView`.
- Change pagination to always display links to the first and last page.

## [0.4.0] - 2020-09-04

### Changed

- Allow usage with newer versions of Flop.

## [0.3.0] - 2020-06-17

### Added

- New option to hide the number of page links.
- New option to limit the number of page links.

### Changed

- Add order and filter parameters to pagination links.

## [0.2.0] - 2020-06-15

### Added

- Improve documentation.

### Changed

- `previous_link/3`, `next_link/3` and `page_links/3` are private functions now.

## [0.1.0] - 2020-06-15

Initial release
