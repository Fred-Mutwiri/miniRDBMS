defmodule MiniRDBMS.Table do
  @moduledoc """
  Represents a single database table.

  Each table will eventually be implemented as a GenServer
  that owns:
  - its rows
  - its indexes
  - its persistence file

  Only this process is allowed to mutate table data.
  """
end
