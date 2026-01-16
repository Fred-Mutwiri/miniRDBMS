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
end
