# EctoAutoFilter

**Automatic Filters based Ecto Schemas**

EctoAutoFilter is a helper for projects that use Ecto Schemas and segregate the queries in entity repository modules. EctoAutoFilter inject the `filter/3` function that by default has a pattern matching for each field of declared entity.

## Installation

EctoAutoFilter can be installed
by adding `ecto_auto_filter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_auto_filter, "~> 1.0.0"}
  ]
end
```

## Get Started
After the installation of dependency, we will add the configuration below so that EctoAutoFilter knows what `repo` module it should execute on queries.

```elixir
# config.exs
config :ecto_auto_filter,
  repo: MyApp.Repo,
```

This configuration apply the `MyApp.Repo` for all entity repositories that use EctoAutoFilter. There are also the possibility of injecting a different `repo` setup for a specific entity repository, for example:

```elixir
# config.exs
defmodule UserRepository do
  use EctoAutoFilter,
    repo: MyApp.AnotherRepo,
    schema: MyApp.User
end
```
Now we will declare the entity repository. Consider the `User` schema.

```elixir
defmodule MyApp.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:age, :integer)
  end
  ...
end
```
Declare the UserRepository using EctoAutoFilter, passing in `schema` parameter the `User` schema and here we will consider that we configured a global `repo`.

```elixir
defmodule UserRepository do
  use EctoAutoFilter,
    schema: MyApp.User
end
```

Done! We just need to test now.

```elixir
iex> user_one = Repo.insert!(%User{name: "John Doe", email: "john@doe.com", age: 30})
iex> user_two = Repo.insert!(%User{name: "Jane Doe", email: "jane@doe.com", age: 28})
iex> UserRepository.filter(%{age: {30, ">="}})
{:ok, 
  [%User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 30,
    email: "john@doe.com",
    id: 1,
    name: "John Doe"
  }]
}
```

## The `filter/3` function
```elixir
@spec filter(map | list, atom, module) :: 
  {:ok, one_result | list} | 
  {:error, :not_found | :filter_not_found | :unsupported_filter } 
def filter(filter, result_format \\ :many, query \\ @base_schema)
```
- `filter`: The first parameter is a map or keywordlist for the filter declaration;
- `result_format`: It's an atom that can be `:one`, `:first` or `:many`, defined by default `:many`;
- `query`: Queriable structure that by default is the base entity.


#### Filter structure

The structure of the filter is a map or a keywordlist in which the keys are field names of the schema to be filtered, e.g: `filter(%{name: "John Doe"})`.
For each key in the filter parameter, EctoAutoFilter concatenate a `where` clause to the `and` logical connector, thus it is possible to compose more complex filters, such as: `filter(%{name: "John Doe", age: 30})`. The filters can receive values directly to an exact value comparison, or values with functions that varing between binary operators or functions such as: `like`, `ilike`, `not_in` or `in`.

- {list, "in | not_in"}: This clause is composed by a tuple with a list and a string `"in"`;
- {value, "> | < | >= | <= | == | !="}: Arithmetical and logical operators;
- {value, "like | ilike"}: Partial search for strings.


### Returning only one value
```elixir
iex> UserRepository.filter(%{age: {28, "=="}}, :one)
{:ok, 
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 28,
    email: "jane@doe.com",
    id: 2,
    name: "Jane Doe"
  }
}
```

### Returning the first found value
```elixir
iex> UserRepository.filter(%{email: {"%doe.com", "like"}}, :first)
{:ok,
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 30,
    email: "john@doe.com",
    id: 1,
    name: "John Doe"
  }
}
```

### Returning all the found values
```elixir
iex> UserRepository.filter(%{email: {"%doe.com", "like"}})
{:ok,[
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 30,
    email: "john@doe.com",
    id: 1,
    name: "John Doe"
  },
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 28,
    email: "jane@doe.com",
    id: 2,
    name: "Jane Doe"
  }
]}
```
## Filters

### By value
```elixir
iex> UserRepository.filter(%{age: {28, "=="}})
{:ok,[
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 28,
    email: "jane@doe.com",
    id: 2,
    name: "Jane Doe"
  }
]}
```
### Between filters
One key of filter can receive a tuple list in which the EctoAutoFilter concatenate by `and` logical operator, such as the example below where we filter the users from 27 to 29 years old.

```elixir
iex> user_three = Repo.insert!(%User{name: "Tom Doe", email: "tom@doe.com", age: 26})
iex> UserRepository.filter(%{age: [{30, "<"}, {26, ">"}]})
{:ok,[
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 28,
    email: "jane@doe.com",
    id: 2,
    name: "Jane Doe"
  }
]}
```

### `in` & `not_in` filter
One key of filter can receive a tuple with a list of values in which the EctoAutoFilter uses `in` or `not_in` to verify the existence or inexistence of the key inside the values from the list.

```elixir
iex> UserRepository.filter(%{id: {[2, 3], "in"}})
{:ok,[
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 28,
    email: "jane@doe.com",
    id: 2,
    name: "Jane Doe"
  },
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 26,
    email: "tom@doe.com",
    id: 3,
    name: "Tom Doe"
  }
]}

iex> UserRepository.filter(%{id: {[2, 3], "not_in"}})
{:ok,[
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 30,
    email: "john@doe.com",
    id: 1,
    name: "John Doe"
  }
]}
```

### `like` & `ilike` filters
```elixir
iex> user_four = Repo.insert!(%User{name: "Norton Doe", email: "norton@doe.com", age: 60})
iex> UserRepository.filter(%{name: {"%to%", "ilike"}})
{:ok,[
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 26,
    email: "tom@doe.com",
    id: 3,
    name: "Tom Doe"
  },
  %User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    age: 60,
    email: "norton@doe.com",
    id: 4,
    name: "Norton Doe"
  }
]}
```

## Errors
- `{:error, :unsupported_filter}`: It occurs when an unknown key is passed inside a filter, returning this error, even if the other keys are correct.

- `{:error, :filter_not_found}`: It is returned in case the filter is empty. 

- `{:error, :unsupported_filter_operator}`: It is returned if one tuple value is passed with an unknown operator.


## Custom Filters
EctoAutoFilter can be extended through its macro `add_filter/4`, see more in [`add_filter/4`](https://hexdocs.pm/ecto_auto_filter/EctoAutoFilter.html#add_filter/4)


## Contributing

Feedback, feature requests, and fixes are welcomed and encouraged. Please make appropriate use of [Issues](https://github.com/brunolouvem/ecto_auto_filter/issues) and [Pull Requests](https://github.com/brunolouvem/ecto_auto_filter/pulls). All code should have accompanying tests.
