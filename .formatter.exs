# Used by "mix format"
[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 80,
  import_deps: [:phoenix_live_view, :stream_data],
  # elixir_ls refuses to import deps... mirror live view config to mitigate
  locals_without_parens: [
    attr: 2,
    attr: 3,
    slot: 1,
    slot: 2,
    slot: 3
  ]
]
