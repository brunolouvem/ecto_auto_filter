defmodule EctoAutoFilter.Test.UserRepository do
  @moduledoc false
  use EctoAutoFilter,
    schema: EctoAutoFilter.Test.User,
    repo: EctoAutoFilter.Test.Repo

  add_filter query, value, :birth_years_ago do
    x_years_ago = 365 * value
    limit_date = Date.utc_today() |> Date.add(-x_years_ago)

    where(query, [r], r.birth_date == ^limit_date)
  end
end
