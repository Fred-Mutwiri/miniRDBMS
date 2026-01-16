defmodule MiniRDBMS.Table do
  @moduledoc """
  Represents a single database table.

  Each table is a GenServer that owns:
  - its rows
  - its primary key index
  - its unique constraints

  now has insert and Select

  Limitations (by design, for now):
    - No projections (SELECT column list)
    - No OR conditions
    - No range predicates
    - No ordering
    * These will be layered on incrementally.

  This process is the sole authority for mutating table data.
  """

  use GenServer

  alias MiniRDBMS.Catalog.Schema

  ###public api
  def start_link(%Schema{} = schema) do
    GenServer.start_link(__MODULE__, schema, name: via_name(schema.name))
  end

  def insert(table_name, row) do
    GenServer.call(via_name(table_name), {:insert, row})
  end

  @doc """
  Returns rows from a table, optionally filtered by a WHERE clause.
  the `where arguement is either:
    -nil(no filtering)
    - a mapof column => valuepairs (equality only)

  Examples:
    select(:users, nil)
    select(:users, %{active: true})
  """
  def select(table_name, where \\ nil) do
    GenServer.call(via_name(table_name), {:select, where})
  end




  #GenServer Callbacks
  @impl true
  def init(schema) do
    state = %{
      schema: schema,
      rows: %{},
      unique_indexes: init_unique_indexes(schema)
    }

    {:ok, state}
  end

  @impl true
  def handle_call( {:insert, row}, _from, state )do
    with :ok <- validate_row(state.schema, row),
         :ok <- enforce_primary_key(state, row),
         :ok <- enforce_unique(state, row) do
          pk = primary_key_value(state.schema, row)

          new_state =
            state
            |> put_row(pk, row)
            |> update_unique_indexes(row)

          {:reply, {:ok, row}, new_state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
   end
  end


  @impl true
  def handle_call({:select, where}, _from, state) do
    rows =
      state.rows
      |> Map.values()
      |> apply_where(where)

    # return rows without altering state. this keeps SELECT referentially transparent from the outside

    {:reply, {:ok, rows}, state}
  end











  #internal helpers
  #______________________________________________________________________________________________________________________
  defp via_name(table_name) do
    {:via, Registry, {MiniRDBMS.TableRegistry, table_name}}
  end

  defp validate_row(%Schema{ columns: columns}, row) do
    case Map.keys(row) --Map.keys(columns) do
      [] -> :ok
      _extra -> {:error, :invalid_columns}
    end
  end

  defp enforce_primary_key(state, row) do
    pk = primary_key_value(state.schema, row)

    if Map.has_key?(state.rows, pk) do
      {:error, :duplicate_primary_key}
    else
      :ok
    end
  end

  def enforce_unique(state, row) do
    Enum.reduce_while(state.schema.unique, :ok, fn col, _acc ->
      value = Map.get(row, col)

      if MapSet.member?(state.unique_indexes[col], value) do
        {:halt, {:error, {:duplicate_unique, col}}}
      else
        {:cont, :ok}
      end
    end)
  end

  defp primary_key_value(%Schema{primary_key: pk}, row) do
    Map.get(row, pk)
  end

  defp put_row(state, pk, row) do
    %{state | rows: Map.put(state.rows, pk, row)}
  end

  defp init_unique_indexes(%Schema{unique: unique}) do
    Map.new(unique, fn col -> {col, MapSet.new()} end)
  end

  defp update_unique_indexes(state, row) do
    new_indexes =
      Enum.reduce(state.unique_indexes, %{}, fn {col, set}, acc ->
        Map.put(acc, col, MapSet.put(set, Map.get(row,col)))
      end)
      %{state | unique_indexes: new_indexes}
  end

  @doc false
  defp apply_where(rows, nil), do: rows

  defp apply_where(rows, where) when is_map(where) do
    Enum.filter(rows, fn row ->
      Enum.all?(where, fn {column, value} ->
        Map.get(row, column) == value
      end)
    end)
  end



end
