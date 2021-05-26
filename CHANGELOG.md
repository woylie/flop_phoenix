# Changelog

## Unreleased

### Changed

- Add wrapper around sortable table header link and order direction indicator.

### Fixed

- Order direction indicator was wrapped twice.

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
