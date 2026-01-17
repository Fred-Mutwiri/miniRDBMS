defmodule MiniRDBMS.Planner.Plan do
  @moduledoc """
  Represents an executable query plan.

  A plan is a *pure data structure* that describes:
  - what operation to perform
  - on which tables
  - using which constraints

  Plans are produced by the Planner and consumed
  by the Executor.

  This separation allows us to reason about *decisions*
  independently from *execution*.
  """

  defstruct [
    :type,
    :table,
    :where,
    :join,
    :updates,
    :insert
  ]
end
