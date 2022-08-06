# Used by "mix format"
[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 80,
  import_deps: [:stream_data],
  locals_without_parens: [
    attr: 2,
    attr: 3
  ]
]
