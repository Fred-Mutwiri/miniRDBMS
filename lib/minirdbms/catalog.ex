defmodule MiniRDBMS.Catalog do
  @moduledoc """
  Manages database metadata.

  The catalog is the authoritative source for:
  - table schemas
  - primary keys
  - unique constraints

  It is implemented as a GenServer to ensure
  serialized, consistent updates.
  """


  use GenServer
  alias MiniRDBMS.Catalog.Schema
  alias MiniRDBMS.Table


  #public api
  @doc """
  Starts the catalog process
  """
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  creates a new table schema in the catalog.
  Returns {:ok, schcema} or {:error, reason}.
  """
  def create_table(name, columns, opts \\ []) do
    GenServer.call(__MODULE__, {:create_table, name, columns, opts})
  end

  @doc """
  Fetch a table schema by name.
  """
  def get_table(name) do
    GenServer.call(__MODULE__, {:get_table, name})
  end

  @doc """
  List all tables known to the catalog.
  """
  def list_tables do
    GenServer.call(__MODULE__, :list_tables)
  end




  #GenServer callbacks
  @impl true
  def init(_initial_state) do
    {:ok, %{}}
  end

  @impl  true
  def handle_call( {:create_table, name, columns, opts}, _from, state ) do
    if Map.has_key?(state, name) do
      {:reply, {:error, :table_already_exists}, state}
    else
      schema =
        %Schema{
          name: name,
          columns: columns,
          primary_key: Keyword.get(opts, :primary_key),
          unique: Keyword.get(opts, :unique, [])
        }
      {:ok, _pid} = Table.start_link(schema)

      {:reply, {:ok, schema}, Map.put(state, name, schema) }
    end
  end

  @impl true
  def handle_call({:get_table, name}, _from, state) do
    case Map.fetch(state, name) do
      {:ok, schema} -> {:reply, {:ok, schema}, state}
      :error -> {:reply, {:error, :table_not_found}, state}
    end
  end

  @impl true
  def handle_call(:list_tables, _from, state) do
    {:reply, Map.keys(state), state}
  end







end
