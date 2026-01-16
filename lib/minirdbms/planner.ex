defmodule MiniRDBMS.Planner do
  @moduledoc """
  Converts parsed SQL ASTs into executable query plans.

  Planning decisions may include:
  - table access strategy
  - index usage
  - join order (very simple)

  Optimization is intentionally minimal.
  """

  def plan(_ast) do
    {:error, :not_implemented}
  end
end
