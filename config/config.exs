import Config

config :phoenix, :json_library, Jason

config :flop_phoenix,
  cursor_pagination: [opts: {Flop.Phoenix.ViewHelpers, :pagination_opts}],
  pagination: [opts: {Flop.Phoenix.ViewHelpers, :pagination_opts}],
  table: [opts: {Flop.Phoenix.ViewHelpers, :table_opts}]
