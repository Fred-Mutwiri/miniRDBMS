defmodule MiniRDBMS.Executor do
  @moduledoc """
  Executes query plans produced by the planner.

  The executor coordinates table processes but does not
  store data itself.
  """

  def execute(_plan) do
    {:error, :not_implemented}
  end
end
