defmodule EctoAutoFilter do
  @moduledoc """
  Ecto Auto Filter
  **Automatic Filters based Ecto Schemas**

  EctoAutoFilter is a helper for projects that use Ecto Schemas and segregate the queries in entity repository modules.
  EctoAutoFilter inject the `filter/3` function that by default has a pattern matching for each field of declared entity.
  """
  @all_binaries_coparable_types ~w(id date integer datetime)a

  @doc """
  Injeta a função `filter/3` e as funções privadas responsáveis pelo filtro customizado a partir do `schema` base passado

  Injects the `filter/3` functions and the privated functions responsible for custom filters from base entity schema's passed.

  Options:
   - `schema`: This options is required and is necessary for EctoAutoFilter build the queries.
   - `repo`: This options is optional and is used to execute the queries, and when is passed such as `use` option, overrides the global config for the current module.

  Exemple:
      defmodule MyApp.User do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
          field(:email, :string)
          field(:age, :integer)
        end
        ...
      end


      defmodule UserRepository do
        use EctoAutoFilter,
          repo: MyApp.Repo,
          schema: MyApp.User
      end

  After that entity repository module is declared the filter functions can already be used like a below example:

  Depois de declarado o using no módulo de repositório as funções de filtro podem ser usadas como no exemplo a seguir:
      iex> user_one = Repo.insert!(%User{name: "John Doe", email: "john@doe.com", age: 30})
      iex> user_two = Repo.insert!(%User{name: "Jane Doe", email: "jane@doe.com", age: 28})
      iex> UserRepository.filter(%{age: {30, ">="}})
      %User{
        __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
        age: 30,
        email: "john@doe.com",
        id: 1,
        name: "John Doe"
      }
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @before_compile EctoAutoFilter

      import Ecto.Query
      import EctoAutoFilter

      @repo opts[:repo] || Application.compile_env(:ecto_auto_filter, :repo)
      @schema opts[:schema]

      @doc false
      def filter(filter, result_format \\ :many, query \\ @schema)

      def filter(filter, _result_format, _query) when filter == %{} or filter == [],
        do: {:error, :filter_not_found}

      def filter(filters, result_format, query) when is_map(filters) or is_list(filters) do
        cond do
          is_map(filters) ->
            build_filters(filters, result_format, query)

          is_list(filters) and Keyword.keyword?(filters) ->
            build_filters(filters, result_format, query)

          true ->
            {:error, :unsupported_filter}
        end
      end

      def filter(_filter, _result_format, _query), do: {:error, :unsupported_filter}

      defp build_filters(filters, result_format, query) do
        Enum.reduce(filters, query, fn
          {field, value}, query ->
            apply_filter(field, query, value)
        end)
        |> run_query(result_format)
        |> handle_result()
      end

      for schema_field <- @schema.__schema__(:fields) do
        field_type = @schema.__schema__(:type, schema_field)

        write_filters_by_type(schema_field, field_type)
        |> Enum.each(fn macro ->
          macro
          |> Macro.expand(__ENV__)
          |> Code.eval_quoted()
        end)
      end

      defp run_query({:error, _} = error_tuple, _result_format), do: error_tuple

      defp run_query(queryable, :one) do
        @repo.one(queryable)
      end

      defp run_query(queryable, :first) do
        @repo.all(queryable)
        |> case do
          [first | _] ->
            first

          _ ->
            nil
        end
      end

      defp run_query(queryable, :many) do
        @repo.all(queryable)
      end

      defp handle_result({:error, _} = error_tuple), do: error_tuple
      defp handle_result(nil), do: {:error, :not_found}
      defp handle_result(result), do: {:ok, result}
    end
  end

  @doc false
  def write_filters_by_type(field_name, field_type)
      when field_type in @all_binaries_coparable_types do
    [
      list_filters(field_name),
      not_in_compare_filter(field_name),
      in_compare_filter(field_name),
      binary_compare_filter(field_name),
      equal_compare_filter(field_name)
    ]
  end

  @doc false
  def write_filters_by_type(field_name, _) do
    [
      list_filters(field_name),
      not_in_compare_filter(field_name),
      in_compare_filter(field_name),
      ilike_filter(field_name),
      like_filter(field_name),
      equal_compare_filter(field_name)
    ]
  end

  defp list_filters(field_name) do
    quote do
      defp apply_filter(unquote(field_name) = field_id, query, values) when is_list(values) do
        Enum.reduce(values, query, fn value, query_acc ->
          apply_filter(field_id, query_acc, value)
        end)
      end
    end
  end

  defp equal_compare_filter(field_name) do
    quote do
      defp apply_filter(unquote(field_name), query, value) do
        where(query, [r], field(r, ^unquote(field_name)) == ^value)
      end
    end
  end

  defp not_in_compare_filter(field_name) do
    quote do
      defp apply_filter(unquote(field_name), query, {values, "not_in"}) when is_list(values) do
        where(query, [r], field(r, ^unquote(field_name)) not in ^values)
      end
    end
  end

  defp in_compare_filter(field_name) do
    quote do
      defp apply_filter(unquote(field_name), query, {values, "in"}) when is_list(values) do
        where(query, [r], field(r, ^unquote(field_name)) in ^values)
      end
    end
  end

  defp ilike_filter(field_name) do
    quote do
      defp apply_filter(unquote(field_name), query, {value, "ilike"}) when is_binary(value) do
        where(query, [r], ilike(field(r, ^unquote(field_name)), ^value))
      end
    end
  end

  defp like_filter(field_name) do
    quote do
      defp apply_filter(unquote(field_name), query, {value, "like"}) when is_binary(value) do
        where(query, [r], like(field(r, ^unquote(field_name)), ^value))
      end
    end
  end

  defp binary_compare_filter(field_name) do
    quote do
      defp apply_filter(unquote(field_name), query, {value, op}) when is_binary(op) do
        case op do
          "==" -> where(query, [r], field(r, ^unquote(field_name)) == ^value)
          "!=" -> where(query, [r], field(r, ^unquote(field_name)) != ^value)
          ">=" -> where(query, [r], field(r, ^unquote(field_name)) >= ^value)
          "<=" -> where(query, [r], field(r, ^unquote(field_name)) <= ^value)
          "<" -> where(query, [r], field(r, ^unquote(field_name)) < ^value)
          ">" -> where(query, [r], field(r, ^unquote(field_name)) > ^value)
          _ -> {:error, :unsupported_filter_operator}
        end
      end
    end
  end

  @doc """
  Adiciona um filtro customizado e componivel aos demais filtros do módulo base em tempo de compilação.
  - query: é queryable que a função irá receber;
  - value: é o valor que será recebido para compor o filtro e pode ser manipulado por pattern matching;
  - key: indentify the created filter in `filter/3` function.

  Este filtro é adicionado as demais regras de filtro e se torna disponível na forma de `filter/3`,
  por exemplo:
      defmodule MyApp.User do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
          field(:email, :string)
          field(:age, :integer)
          field(:bith_date, :date)
        end
        ...
      end


      defmodule UserRepository do
        use EctoAutoFilter,
          repo: MyApp.Repo,
          schema: MyApp.User

        add_filter query, value, :birth_years_ago do
          x_years_ago = (365 * value)
          limit_date = Date.utc_today() |> Date.add(-x_years_ago)

          where(query, [r], r.birth_date == ^limit_date)
        end
      end

  Depois de declarado o filtro customizado ele pode ser usado conforme o exemplo a seguir:
      iex> user_one = Repo.insert!(%User{name: "John Doe", email: "john@doe.com", age: 30, birth_date: 1991-01-01})
      iex> user_two = Repo.insert!(%User{name: "Jane Doe", email: "jane@doe.com", age: 28, birth_date: 1993-01-01})
      iex> UserRepository.filter(%{birth_years_ago: 28})
      %User{
        __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
        age: 28,
        email: "jane@doe.com",
        id: 2,
        name: "Jane Doe"
      }
  """
  defmacro add_filter(query, value, key, do: block) do
    quote do
      defp apply_filter(unquote(key), unquote(query), unquote(value)) do
        unquote(block)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defp apply_filter(_, _, _), do: {:error, :unsupported_filter}
    end
  end
end
