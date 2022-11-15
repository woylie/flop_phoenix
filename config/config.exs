import Config

config :phoenix, :json_library, Jason

config :flop_phoenix,
  cursor_pagination: [opts: {MyAppWeb.CoreComponents, :pagination_opts}],
  pagination: [opts: {MyAppWeb.CoreComponents, :pagination_opts}],
  table: [opts: {MyAppWeb.CoreComponents, :table_opts}]
