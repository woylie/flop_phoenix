# Changelog

## Unreleased

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
