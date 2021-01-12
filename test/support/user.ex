defmodule EctoAutoFilter.Test.User do
  @moduledoc false
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:age, :integer)
    field(:birth_date, :date)
    field(:occupation, :string)
    field(:nickname, :string)
  end
end
