defmodule MiniRDBMS.SQL.Parser do
  @moduledoc """
  Parses SQL-like input into an abstract syntax tree (AST).

  This module is:
  - pure
  - stateless
  - side-effect free

  It knows nothing about storage or execution.
  """

  def parse(_sql_string) do
    {:error, :not_implemented}
  end
end
