defmodule MiniRDBMS do
  @moduledoc """
  Public API for MiniRDBMS.

  This module is the single entry point used by:
  - the REPL
  - the web application
  - future integrations

  Internal modules should not be accessed directly by external callers.
  """

  def start do
    Application.ensure_all_started(:minirdbms)
  end

  @doc """
    Executes a SQL-like command string.
    This function:
      - parses SQL
      - dispatches to the appropriate table operation
    Planning and optimization are intentionally minimal at this stage.
  """
  def execute(sql) when is_binary(sql) do
    with {:ok, ast} <- MiniRDBMS.SQL.Parser.parse(sql),
         {:ok, result} <- dispatch(ast) do
      {:ok, result}
    else
      error -> error
     end
  end

  def create_table(name, columns, opts \\ []) do
    MiniRDBMS.Catalog.create_table(name, columns, opts)
  end

  def list_tables do
    MiniRDBMS.Catalog.list_tables()
  end

  def get_table(name) do
    MiniRDBMS.Catalog.get_table(name)
  end

  def insert(table_name, row) do
    MiniRDBMS.Table.insert(table_name, row)
  end

  @doc """
    Executes a SELECT against a table.
    Currently supports:
    - SELECT *
    - Optional WHERE with equality filters
    Returns:
        {:ok, list_of_rows}
  """
  def select(table_name, where \\ nil) do
    MiniRDBMS.Table.select(table_name, where)
  end




  #internal helpers

  defp dispatch(%{type: :insert, table: table, columns: cols, values: vals}) do
    row = Enum.zip(cols, vals) |> Map.new()
    MiniRDBMS.Table.insert(table, row)
  end

  defp dispatch(%{type: :select, table: table, where: where}) do
    MiniRDBMS.Table.select(table, where)
  end

  defp dispatch(%{type: :update, table: table, set: updates, where: where}) do
    MiniRDBMS.Table.update(table, updates, where)
  end

  defp dispatch(%{ type: :delete, table: table, where: where}) do
    MiniRDBMS.Table.delete(table, where)
  end
end
