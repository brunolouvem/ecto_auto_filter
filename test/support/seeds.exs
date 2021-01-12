EctoAutoFilter.Test.Repo.start_link()

calc_birth_date = fn age ->
  Date.utc_today() |> Date.add(-(age * 365))
end

fintch_age = 58

%EctoAutoFilter.Test.User{
  birth_date: calc_birth_date.(fintch_age),
  email: "harold@machine.com",
  age: fintch_age,
  name: "Harold Fintch",
  nickname: "fintch",
  occupation: "hacker"
}
|> EctoAutoFilter.Test.Repo.insert!()

reese_age = 42

%EctoAutoFilter.Test.User{
  birth_date: calc_birth_date.(reese_age),
  email: "john@machine.com",
  age: reese_age,
  name: "John Reese",
  occupation: "agent",
  nickname: "reese"
}
|> EctoAutoFilter.Test.Repo.insert!()

fusco_age = 43

%EctoAutoFilter.Test.User{
  birth_date: calc_birth_date.(fusco_age),
  email: "fusco@machine.com",
  age: fusco_age,
  name: "Lionel Fusco",
  occupation: "detective",
  nickname: "fusco"
}
|> EctoAutoFilter.Test.Repo.insert!()

root_age = 36

%EctoAutoFilter.Test.User{
  birth_date: calc_birth_date.(root_age),
  email: "root@machine.com",
  age: root_age,
  name: "Samantha Groves",
  nickname: "root",
  occupation: "hacker"
}
|> EctoAutoFilter.Test.Repo.insert!()

shaw_age = 32

%EctoAutoFilter.Test.User{
  birth_date: calc_birth_date.(shaw_age),
  email: "shaw@machine.com",
  age: shaw_age,
  name: "Sameen Shaw",
  nickname: "shaw",
  occupation: "agent"
}
|> EctoAutoFilter.Test.Repo.insert!()
