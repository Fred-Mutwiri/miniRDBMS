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
    Executes a SQL-like command against the database.
    This function will later coordinate parsing, planning,
    and execution.
  """
  def execute(_sql_string) do
    {:error, :not_implemented}
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
end
