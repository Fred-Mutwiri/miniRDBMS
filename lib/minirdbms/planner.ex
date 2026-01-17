defmodule MiniRDBMS.Planner do
  @moduledoc """
  Converts parsed SQL ASTs into executable query plans.

   Responsibilities:
  - validate high-level query structure
  - decide *what kind* of operation is required
  - produce a plan data structure

  Non-responsibilities:
  - no data access
  - no execution
  - no side effects

  Optimization is intentionally minimal.
  """

  alias MiniRDBMS.Planner.Plan

  @doc """
  Produces an execution plan from a parsed AST
  Returns:
    {:ok, %Plan{}}
    {:error, reason}
  """
  def plan(ast) when is_map(ast) do
    {:ok, do_plan(ast)}
  end

  #Internal planning logic

  defp do_plan(%{type: :insert} = ast) do
    %Plan{
      type: :insert,
      insert: ast
    }
  end
  defp do_plan(%{type: :select, join: join} = ast) when not is_nil(join) do
    %Plan{
      type: :join,
      join: join,
      where: Map.get(ast, :where)
    }
  end
  defp do_plan(%{type: :select} = ast) do
    %Plan{
      type: :select,
      table: ast.table,
      where: ast.where
    }
  end

  defp do_plan(%{type: :delete} = ast) do
    %Plan{
      type: :delete,
      table: ast.table,
      where: ast.where
    }
  end
end
