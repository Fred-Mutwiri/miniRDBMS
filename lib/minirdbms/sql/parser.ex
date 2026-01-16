defmodule MiniRDBMS.SQL.Parser do
  @moduledoc """
    Very small SQL-like parser.
    Supported statements:
      - INSERT INTO table (col, col) VALUES (val, val);
      - SELECT * FROM table;
      - SELECT * FROM table WHERE col = val;
      - UPDATE table SET col = val WHERE col = val;
      - DELETE FROM table WHERE col = val;
    This parser is intentionally naive:
      - No full SQL grammar
      - No error recovery
      - Whitespace-sensitive in places
    Its purpose is educational clarity
  """

  @doc """
  parses a SQL string into a simple AST map.
  Returns:
    {:ok, ast}
    {:error, reason}
  """
  def parse(sql) when is_binary(sql) do
    sql
    |> String.trim()
    |> String.trim_trailing(";")
    |> do_parse()
  end





  # internal helpers

  defp do_parse(sql) do
    up = String.upcase(sql)

    cond do
      String.starts_with?(up, "INSERT") -> parse_insert(sql)
      String.starts_with?(up, "SELECT") -> parse_select(sql)
      String.starts_with?(up, "UPDATE") -> parse_update(sql)
      String.starts_with?(up, "DELETE") -> parse_delete(sql)
      true -> {:error, :unsupported_statement}
    end
  end

  # defp do_parse(sql) do
  #   cond do
  #     String.starts_with?(String.upcase(sql), "INSERT") ->
  #       parse_insert(sql)
  #     String.starts_with?(String.upcase(sql), "SELECT") ->
  #       parse_select(sql)

  #     true ->
  #       {:error, :unsupported_statement}
  #   end
  # end

  defp parse_insert(sql) do
    #Example:
    #INSERT INTO users (id, name) VALUES (1,"Brian")

    with [_, rest] <- String.split(sql, "INTO", parts: 2),
         [table_and_cols, values_part] <- String.split(rest, "VALUES", parts: 2),
         {table, columns } <- parse_table_and_columns(table_and_cols),
         values <- parse_values(values_part) do
          {:ok,
            %{
              type: :insert,
              table: table,
              columns: columns,
              values: values
            }
        }
    else
      _ -> {:error, :invalid_insert_syntax}
    end
  end

  defp parse_table_and_columns(segment) do
    #" users (id, name)"
    [table_part, cols_part] =
      segment
      |> String.trim()
      |>String.split("(", parts: 2)

    table =
      table_part
      |> String.trim()
      |> String.to_atom()

    columns =
      cols_part
      |> String.trim_trailing(")")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.to_atom/1)

    {table, columns}
  end

  defp parse_values(segment) do
    #(1, \"Brian\")
    segment
    |> String.trim()
    |> String.trim_leading("(")
    |> String.trim_trailing(")")
    |> String.split(",")
    |> Enum.map(&parse_literal/1)

  end

  defp parse_literal(value) do
    value = String.trim(value)

    case String.downcase(value) do
      "true" -> true
      "false" -> false
      _ ->
        cond do
          String.starts_with?(value, "\"") ->
            String.trim(value, "\"")

          true ->
            String.to_integer(value)
        end
    end
  end

  defp parse_select(sql) do
    case String.split(sql, ~r/\s+WHERE\s+/i, parts: 2) do
      [select_part] ->
        {:ok, base_select(select_part, nil)}

      [select_part, where_part] ->
        {:ok, base_select(select_part, parse_where(where_part))}
    end
  end

  # defp parse_select(sql) do
  #   #SELECT * FROM table WHERE col = val

  #   sql = String.upcase(sql)

  #   case String.split(sql, "WHERE", parts: 2 )  do
  #     [select_part] ->
  #       {:ok, base_select(select_part, nil)}

  #     [select_part, where_part] ->
  #       {:ok, base_select(select_part, parse_where(where_part))}
  #   end
  # end

  defp base_select(select_part, where) do
    table =
      select_part
      |> String.split("FROM", parts: 2)
      |> List.last()
      |> String.trim()
      |> String.to_atom()
    %{
      type: :select,
      table: table,
      where: where
    }
  end

  defp parse_where(segment) do
    #col = val
    [col, val] =
      segment
      |> String.trim()
      |> String.split("=", parts: 2)

    %{String.to_atom(String.trim(col)) => parse_literal(val)}
  end


  defp parse_update(sql) do
    #UPDATE users SET active = false WHERE id = 3

    with [_, rest] <- String.split(sql, "UPDATE", parts: 2),
         [table_part, rest] <- String.split(rest, "SET", parts: 2),
         [set_part, where_part] <- String.split(rest, "WHERE", parts: 2) do
      {:ok,
        %{
          type: :update,
          table: table_part |> String.trim() |> String.to_atom(),
          set: parse_assignments(set_part),
          where: parse_where(where_part)
        }
    }  else
      _ -> {:error, :invalid_update_syntax}
    end
  end

  defp parse_assignments(segment) do
    # col = val, col = cal
    segment
    |> String.split(",")
    |> Enum.map(&String.split(&1, "=", parts: 2))
    |> Enum.map(fn [k,v] ->
      {String.to_atom(String.trim(k)), parse_literal(v)}
    end)
    |> Map.new()
  end

  defp parse_delete(sql) do
    #DELETE FROM users WHERE active = false
    with [_,rest] <- String.split(sql, "FROM", parts: 2),
         [table_part, where_part] <- String.split(rest, "WHERE", parts: 2) do
      {:ok,
        %{
          type: :delete,
          table: table_part |> String.trim() |> String.to_atom(),
          where: parse_where(where_part)
        }
    }  else
      _ -> {:error, :invalid_delete_syntax}
        end
  end
end
