defmodule MiniRDBMS.Executor do
  @moduledoc """
  Executes query plans.

  Currently supports:
  - simple SELECT
  - simple INNER JOIN (equality only)
  """

  alias MiniRDBMS.Table



  alias MiniRDBMS.Planner.Plan
  alias MiniRDBMS.Catalog
  alias MiniRDBMS.Types

  @doc """
    Performs a simple INNER JOIN using nested loops.
    Semantics:
      - equality only
      - no WHERE
      - returns merged rows
  """
  def inner_join(left_table, right_table, left_col, right_col) do
    {:ok, left_rows} = Table.select(left_table)
    {:ok, right_rows} = Table.select(right_table)

    rows =
      for l <- left_rows,
          r <- right_rows,
          Map.get(l, left_col) == Map.get(r, right_col) do
        Map.merge(l, r)
      end

    {:ok, rows}
  end


  @doc """
  Executes a query plan produced by the planner.
  the executor:
    - performs side effects
    - commnicates with table processes
    - returns query results
    It does not parse SQL or make planning decisions.
  """
  def execute(%Plan{type: :insert, insert: insert_ast}) do
    %{table: table, columns: cols, values: vals} = insert_ast
    row = Enum.zip(cols, vals) |> Map.new()

    with {:ok, schema} <- Catalog.get_table(table),
        {:ok, casted_row} <- validate_and_cast_row(schema, row),
        {:ok, inserted} <- Table.insert(table, casted_row) do
      {:ok, inserted}
    end
  end


  def execute(%Plan{type: :select, table: table, where: where}) do
    Table.select(table, where)
  end

  def execute(%Plan{type: :update, table: table, updates: updates, where: where})do
    Table.update(table, updates, where)
  end

  def execute(%Plan{type: :delete, table: table, where: where}) do
    Table.delete(table, where)
  end

  def execute(%Plan{type: :join, join: join, where: where}) do
    %{left: left, right: right, on: {left_col, right_col}} = join

    with {:ok, rows} <- inner_join(left, right, left_col, right_col) do
      {:ok, apply_where(rows, where)}
    end
  end






  # Internal Helper:
  defp apply_where(rows,nil), do: rows

  defp apply_where(rows, where) do
   Enum.filter(rows, fn row ->
    Enum.all?(where, fn {col, val} ->
      Map.get(row, col) == val
    end)
   end)
  end

  defp validate_and_cast_row(schema, row) do
    Enum.reduce_while(schema.columns, {:ok, %{}}, fn {col, type}, {:ok, acc} ->
      case Map.fetch(row, col) do
        {:ok, value} ->
          case Types.cast(type, value) do
            {:ok, casted} -> {:cont, {:ok, Map.put(acc, col, casted)}}
            {:error, _} -> {:halt, {:error, {:invalid_type, col}}}
          end

        :error ->
          {:halt, {:error, {:missing_column, col}}}
      end
    end)
  end

end
