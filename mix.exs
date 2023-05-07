defmodule FlopPhoenix.MixProject do
  use Mix.Project

  @source_url "https://github.com/woylie/flop_phoenix"
  @version "0.18.2"

  def project do
    [
      app: :flop_phoenix,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test,
        credo: :test,
        dialyzer: :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        plt_file: {:no_warn, ".plts/dialyzer.plt"}
      ],
      name: "Flop Phoenix",
      source_url: @source_url,
      homepage_url: @source_url,
      description: description(),
      package: package(),
      docs: docs(),
      consolidate_protocols: Mix.env() != :test
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7.0", only: [:test], runtime: false},
      {:dialyxir, "~> 1.3.0", only: [:test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:ex_machina, "~> 2.4", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:floki, "~> 0.34.0", only: :test},
      {:flop, ">= 0.17.1 and < 0.21.0"},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:phoenix, "~> 1.6.0 or ~> 1.7.0"},
      {:phoenix_html, "~> 3.3.0"},
      {:phoenix_live_view, "~> 0.18.0"},
      {:stream_data, "~> 0.5", only: [:dev, :test]}
    ]
  end

  defp description do
    """
    Phoenix components for pagination, sortable tables and filter forms using Flop.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/blob/main/CHANGELOG.md",
        "Sponsor" => "https://github.com/sponsors/woylie"
      },
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: @version,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_docs: [
        Components: &(&1[:section] == :components),
        Miscellaneous: &(&1[:section] == :miscellaneous)
      ]
    ]
  end
end
