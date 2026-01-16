defmodule MiniRDBMS.Catalog.Schema do
  @moduledoc """
  Represents the schema of a database table.

  This is pure metadata — it contains no data rows.
  """

  @enforce_keys [:name, :columns]
  defstruct [
    :name,
    :columns,
    primary_key: nil,
    unique: []
  ]
end
