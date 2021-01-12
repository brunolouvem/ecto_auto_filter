defmodule EctoAutoFilter.Test.Repo.Migrations.AddUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:email, :string)
      add(:age, :integer)
      add(:birth_date, :date)
      add(:occupation, :string)
      add(:nickname, :string)
    end
  end
end
