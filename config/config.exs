import Config

config :phoenix, :json_library, Jason

config :flop_phoenix,
  table: [opts: {MyAppWeb.CoreComponents, :table_opts}]
