defmodule MiniRDBMS.Executor do
  @moduledoc """
  Executes query plans.

  Currently supports:
  - simple SELECT
  - simple INNER JOIN (equality only)
  """

  alias MiniRDBMS.Table

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
end
