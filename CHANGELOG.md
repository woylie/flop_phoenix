# Changelog

## Unreleased

### Changed

- The `for`, `event` and `target` options moved from the `opts` assign to the
  root. The `opts` assign is now exclusively used for customization options
  that modify the appearance. These options are usually set globally for a
  project and are not related to the specific data or view.
- The `row_func/2` function passed to the `table` component receives a keyword
  list with all additional assigns now instead of the `opts` assign.
- The pagination and table components only pass the `for` option to the query
  builder, instead of all `opts`.
- The `opts` assign for the pagination and table components is now optional.

#### How to update

Remove `for`, `event`, `target` and any additional parameters needed by your
`row_func` and add them as regular assigns.

For example, if your `row_func` looks like this:

```elixir
def table_row(%Pet{id: id, name: name}, opts) do
  socket = Keyword.fetch!(opts, :socket)
  [name, link("show", to: Routes.pet_path(socket, :show, id))]
end
```

Change this:

```elixir
<Flop.Phoenix.sortable_table
  row_func={&table_row/2}
  opts={[
    container: true,
    for: Pet,
    event: "sort-table",
    target: @myself,
    socket: @socket
  ]}
  ...
/>

<Flop.Phoenix.pagination
  row_func={&table_row/2}
  opts={[
    for: Pet,
    event: "sort-table",
    target: @myself,
    page_links: {:ellipsis, 7}
  ]}
  ...
/>
```

To this:

```elixir
<Flop.Phoenix.sortable_table
  for={Pet}
  event="sort-table"
  target={@myself}
  row_func={&table_row/2}
  opts={[container: true]}
  socket={@socket}
  ...
/>

<Flop.Phoenix.pagination
  for={Pet}
  event="sort-table"
  target={@myself}
  row_func={&table_row/2}
  opts={[page_links: {:ellipsis, 7}]}
  ...
/>
```

## [0.9.1] - 2021-10-22

### Changed

- Change `live_view` version requirement to `~> 0.16.0 or ~> 0.17.0`.

## [0.9.0] - 2021-10-04

### Added

- Add table footer option for sortable table.

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
