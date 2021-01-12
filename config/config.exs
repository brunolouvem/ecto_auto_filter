# General application configuration
use Mix.Config

config :ecto_auto_filter,
  ecto_repos: [EctoAutoFilter.Test.Repo]

config :ecto_auto_filter, EctoAutoFilter.Test.Repo,
  priv: "test/support/",
  url: System.get_env("DATABASE_URL") || "postgres://localhost:5432/ecto_auto_filter",
  pool_size: 10
