defmodule EctoAutoFilter.MixProject do
  use Mix.Project

  @version "0.1.0"
  def project do
    [
      app: :ecto_auto_filter,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Hex
      description: "A Helpers Set for build automatic filters on Ecto Schemas",
      package: package(),

      # Docs
      name: "Ecto Auto Filter",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.2"},
      {:ecto_sql, "~> 3.4", only: [:dev, :test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]},
      {:credo, "~> 1.4", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.22", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Bruno Louvem"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/brunolouvem/ecto_auto_filter"},
      files: ~w(.formatter.exs mix.exs README.md CHANGELOG.md lib/)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/ecto_auto_filter",
      source_url: "https://github.com/brunolouvem/readme",
      extras: ["README.md"]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run test/support/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      ci: [
        "format --check-formatted",
        "credo --strict",
        "test --raise",
        "dialyzer"
      ],
      "test.ci": [
        "ecto.setup",
        "ci"
      ]
    ]
  end
end
