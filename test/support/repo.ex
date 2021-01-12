defmodule EctoAutoFilter.Test.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :ecto_auto_filter,
    adapter: Ecto.Adapters.Postgres
end
