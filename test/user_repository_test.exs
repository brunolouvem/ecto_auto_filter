defmodule UserRepositoryTest do
  use ExUnit.Case, async: false
  alias EctoAutoFilter.Test.UserRepository

  setup do
    [:reese, :fintch, :fusco, :shaw, :root]
    |> Enum.reduce(Keyword.new(), fn person_name, acc ->
      case UserRepository.filter(%{nickname: Atom.to_string(person_name)}, :one) do
        {:ok, person} ->
          Keyword.put(acc, person_name, person)

        _ ->
          acc
      end
    end)
  end

  describe "Filter from exact match" do
    test "get a user from id", %{fintch: fintch} do
      assert {:ok, [^fintch]} = UserRepository.filter(%{id: fintch.id})
    end

    test "get a user from age", %{reese: reese} do
      assert {:ok, [^reese]} = UserRepository.filter(%{age: 42})
    end

    test "get a user from exact birth_date", %{fusco: fusco} do
      assert {:ok, [^fusco]} = UserRepository.filter(%{birth_date: fusco.birth_date})
      assert {:ok, [^fusco]} = UserRepository.filter(%{birth_date: {fusco.birth_date, "=="}})
    end

    test "get a user from exact email", %{fintch: fintch} do
      assert {:ok, [^fintch]} = UserRepository.filter(%{email: "harold@machine.com"})
    end

    test "get a user from exact name", %{reese: reese} do
      assert {:ok, [^reese]} = UserRepository.filter(%{name: "John Reese"})
      assert {:ok, []} = UserRepository.filter(%{name: "Reese"})
    end
  end

  describe "Filter from like and ilike match" do
    test "get a user from parcial name", %{root: root, shaw: shaw} do
      assert {:ok, [^root, ^shaw]} = UserRepository.filter(%{name: {"Sam%", "like"}})
    end

    test "get a user from parcial name or email", %{fintch: fintch, shaw: shaw} do
      assert {:ok, [^fintch, ^shaw]} =
               UserRepository.filter(%{name: {"%ha%", "ilike"}, email: {"%ha%", "ilike"}})
    end
  end

  describe "Filter between values" do
    test "get a user between age", %{fusco: fusco, reese: reese, fintch: fintch} do
      assert {:ok, [^reese, ^fusco]} = UserRepository.filter(%{age: [{50, "<"}, {40, ">"}]})
      assert {:ok, [^fintch]} = UserRepository.filter(%{age: [{50, ">="}]})
    end

    test "get a user between birth_date", %{
      shaw: shaw,
      fintch: fintch,
      reese: reese,
      root: root,
      fusco: fusco
    } do
      assert {:ok, []} =
               UserRepository.filter(%{
                 birth_date: [
                   {fintch.birth_date, "=="},
                   {shaw.birth_date, "=="}
                 ]
               })

      assert {:ok, [^reese, ^fusco, ^root]} =
               UserRepository.filter(%{
                 birth_date: [
                   {fintch.birth_date, ">"},
                   {shaw.birth_date, "<"}
                 ]
               })
    end
  end

  describe "Custom filters" do
    test "get a user birthed x years ago", %{fintch: fintch} do
      assert {:ok, [^fintch]} = UserRepository.filter(%{birth_years_ago: 58})
    end
  end

  describe "Composable filters" do
    test "get a users by age and birth_date", %{reese: reese, fusco: fusco} do
      assert {:ok, [^reese, ^fusco]} =
               UserRepository.filter(%{age: {50, "<"}, birth_date: {reese.birth_date, "<="}})
    end

    test "get a users by occupation and age", %{reese: reese, shaw: shaw, root: root} do
      assert {:ok, [^reese, ^root, ^shaw]} =
               UserRepository.filter(%{occupation: {["hacker", "agent"], "in"}, age: {58, "<"}})
    end
  end
end
