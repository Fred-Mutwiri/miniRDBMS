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
         {:ok, plan} <- MiniRDBMS.Planner.plan(ast),
         {:ok, result} <- MiniRDBMS.Executor.execute(plan) do
      {:ok, result}
    else
      error -> error
    end
  end

  #metadata helpers:
  def create_table(name, columns, opts \\ []) do
    MiniRDBMS.Catalog.create_table(name, columns, opts)
  end

  def list_tables do
    MiniRDBMS.Catalog.list_tables()
  end

  def get_table(name) do
    MiniRDBMS.Catalog.get_table(name)
  end


end
