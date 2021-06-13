# Changelog

## Unreleased

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
