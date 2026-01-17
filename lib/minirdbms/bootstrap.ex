defmodule MiniRDBMS.Bootstrap do
  @moduledoc """
  One-shot bootstrapping of persisted database state.

  Responsibilities:
  - Load all persisted table schemas
  - Register schemas in the catalog
  - Start each table GenServer

  Note:
  Table processes handle their own state restoration and persistence.
  """

  alias MiniRDBMS.{Catalog, Table, Storage}

  @doc """
  Start the bootstrap process.

  This function:
  - Scans the data directory for persisted tables
  - Registers each schema in the catalog
  - Starts a GenServer for each table

  Returns :ok when done.
  """
  def start do
    # ensure data directory exists
    Storage.ensure_storage_dir!()

    # scan data directory for table files
    File.ls!("data")
    |> Enum.filter(&String.ends_with?(&1, ".db"))
    |> Enum.each(fn file ->
      table_name =
        file
        |> Path.rootname()
        |> String.to_atom()

      # load persisted table to get schema
      {:ok, state} = Storage.load(table_name)
      schema = state.schema

      # register schema in catalog
      Catalog.register_schema(schema)

      # start table process (will auto-load persisted state)
      {:ok, _pid} = Table.start_link(schema)
    end)

    :ok
  end
end
