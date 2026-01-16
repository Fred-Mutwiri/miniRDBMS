defmodule MiniRDBMS.Index do
  @moduledoc """
  Implements simple equality-based indexes.

  An index maps:
      column_value -> list of row positions

  Design constraints:
  - equality lookups only
  - no range scans
  - no composite keys
  - correctness over performance

  Indexes are maintained by table processes and are
  never accessed directly by external callers.

  ### Indexing

  MiniRDBMS supports basic equality-based indexing.

  - indexes are defined per column
  - only `column = value` lookups are indexed
  - indexes are maintained automatically
  - no composite or range indexes

  Indexes are rebuilt when necessary to favor correctness
  and simplicity.

  """


  @doc """
  Builds an index for a given column from existing rows.
  """
  def build(rows, column) do
    Enum.reduce(rows, %{}, fn {row, idx}, acc ->
      value = Map.get(row, column)
      Map.update(acc, value, [idx, &[idx | &1]])
    end)
  end

  @doc """
    Insert a row reference into an index.
  """
  def insert(index, value, row_id) do
    Map.update(index, value, [row_id], &[row_id | &1])
  end

  @doc """
    Removes a row reference from an index.
  """
  def delete(index, value, row_id) do
    index
    |> Map.get(value, [])
    |> List.delete(row_id)
    |> case do
      [] -> Map.delete(index, value)
      remaining -> Map.put(index, value, remaining)
    end
  end

end
