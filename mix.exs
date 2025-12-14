defmodule FlopPhoenix.MixProject do
  use Mix.Project

  @source_url "https://github.com/woylie/flop_phoenix"
  @version "0.25.3"

  def project do
    [
      app: :flop_phoenix,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        plt_file: {:no_warn, ".plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit]
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

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test,
        credo: :test,
        dialyzer: :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "== 1.7.14", only: [:test], runtime: false},
      {:dialyxir, "1.4.7", only: [:test], runtime: false},
      {:ex_doc, "0.39.3", only: :dev, runtime: false},
      {:ex_machina, "2.8.0", only: :test},
      {:excoveralls, "0.18.5", only: :test},
      {:floki, "0.38.0", only: :test},
      {:lazy_html, "0.1.8", only: :test},
      {:flop, ">= 0.23.0 and < 0.27.0"},
      {:jason, "1.4.4", only: [:dev, :test]},
      {:makeup_css, "0.2.3", only: :dev, runtime: false},
      {:makeup_diff, "0.1.1", only: :dev, runtime: false},
      {:makeup_eex, "2.0.2", only: :dev, runtime: false},
      {:makeup_html, "0.2.0", only: :dev, runtime: false},
      {:phoenix, ">= 1.6.0 and < 1.9.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 1.0.6 or ~> 1.1.0"},
      {:stream_data, "1.2.0", only: [:dev, :test]}
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
      files: ~w(lib .formatter.exs mix.exs CHANGELOG* README* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "guides/recipes/css_styles.md",
        "guides/recipes/load_more_and_infinite_scroll.md",
        "guides/recipes/page_size_control.md",
        "README.md",
        "CHANGELOG.md"
      ],
      source_ref: @version,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_extras: [
        Recipes: ~r/recipes\/.?/
      ],
      groups_for_docs: [
        Components: &(&1[:section] == :components)
      ]
    ]
  end
end
