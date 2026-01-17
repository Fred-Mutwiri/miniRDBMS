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

    WHERE semantics:
    - Equality only
    - AND-only (implicit)
    - No OR, no ranges
    These limitations are intentional and documented.

  This process is the sole authority for mutating table data.
  """

  use GenServer

  alias MiniRDBMS.Catalog.Schema
  alias MiniRDBMS.Storage


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

  @doc """
  updates rows matching the WHERE clause.
  Returns the number of Rows updated
  """
  def update(table_name, updates, where) do
    GenServer.call(via_name(table_name), {:update, updates, where})
  end

  @doc """
  Deletes rows matching the WHERE clause.

  Returns the number of rows deleted.
  """
  def delete(table_name, where) do
    GenServer.call(via_name(table_name), {:delete, where})
  end





  #GenServer Callbacks
  @impl true
  def init(schema) do
    # Attempt to load persisted state
    state =
      case Storage.load(schema.name) do
        {:ok, persisted_state} ->
          # Ensure schema field is updated
          Map.put(persisted_state, :schema, schema)

        {:error, :not_found} ->
          %{
            schema: schema,
            rows: %{},
            unique_indexes: init_unique_indexes(schema),
            indexes: init_indexes(schema)
          }
      end

    # Persist immediately to guarantee consistency on disk
    Storage.save(schema.name, state)

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
            |> update_indexes_on_insert(pk, row)

          Storage.save(state.schema.name, new_state)

          {:reply, {:ok, row}, new_state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
   end
  end


  @impl true
  def handle_call({:select, where}, _from, state) do
    rows =
      cond do
        is_map(where) and map_size(where) == 1 ->
          [{column, value}] = Map.to_list(where)
          select_with_optional_index(state, column, value, where)

        true ->
          state.rows
          |> Map.values()
          |> apply_where(where)
      end

    {:reply, {:ok, rows}, state}
  end


  # def handle_call({:select, where}, _from, state) do
  #   rows =
  #     state.rows
  #     |> Map.values()
  #     |> apply_where(where)

  #   # return rows without altering state. this keeps SELECT referentially transparent from the outside

  #   {:reply, {:ok, rows}, state}
  # end

  def handle_call({:update, updates, where}, _from, state) do
    {updated_rows, count} =
      Enum.map_reduce(state.rows, 0, fn {pk, row}, acc ->
        if matches_where?(row, where) do
          {{pk, Map.merge(row, updates)}, acc + 1}
        else
          {{pk, row}, acc}
        end
      end)

    new_state =
      state
      |> Map.put(:rows, Map.new(updated_rows))
      |> rebuild_indexes()
      |> rebuild_unique_indexes()

    Storage.save(state.schema.name, new_state)

    {:reply, {:ok, count}, new_state}
  end

  def handle_call({:delete, where}, _from, state) do
    {remaining, deleted} =
      Enum.split_with(state.rows, fn {_pk, row} ->
        not matches_where?(row, where)
      end)

    new_state =
      state
      |> Map.put(:rows, Map.new(remaining))
      |> rebuild_indexes()
      |> rebuild_unique_indexes()

    Storage.save(state.schema.name, new_state)

    {:reply, {:ok, length(deleted)}, new_state}
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

  defp init_indexes(%Schema{indexes: indexed_columns}) do
    Map.new(indexed_columns, fn col ->
      {col, %{}}
    end)
  end

  defp update_indexes_on_insert(state, pk, row) do
    new_indexes =
      Enum.reduce(state.indexes, %{}, fn {col, index}, acc ->
        value = Map.get(row, col)

        updated =
          Map.update(index, value, MapSet.new([pk]), fn set ->
            MapSet.put(set, pk)
          end)

        Map.put(acc, col, updated)
      end)

    %{state | indexes: new_indexes}
  end

  defp rebuild_indexes(%{schema: schema, rows: rows} = state) do
    new_indexes =
      Enum.reduce(schema.indexes, %{}, fn col, acc ->
        index =
          Enum.reduce(rows, %{}, fn {pk, row}, acc ->
            value = Map.get(row, col)

            Map.update(acc, value, MapSet.new([pk]), fn set ->
              MapSet.put(set, pk)
            end)
          end)

        Map.put(acc, col, index)
      end)

    %{state | indexes: new_indexes}
  end


  defp rebuild_unique_indexes(%{schema: schema, rows: rows} = state) do
    new_unique =
      Enum.reduce(schema.unique, %{}, fn col, acc ->
        values =
          rows
          |> Map.values()
          |> Enum.map(&Map.get(&1, col))
          |> MapSet.new()

        Map.put(acc, col, values)
      end)

    %{state | unique_indexes: new_unique}
  end


  defp select_with_optional_index(state, column, value, where) do
    case Map.get(state.indexes, column) do
      nil ->
        state.rows
        |> Map.values()
        |> apply_where(where)

      index ->
        index
        |> Map.get(value, MapSet.new())
        |> Enum.map(&Map.get(state.rows, &1))
    end
  end






















  #internal helpers


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

  defp matches_where?(_row, nil), do: true

  defp matches_where?(row, where) when is_map(where) do
    Enum.all?(where, fn {column, value} ->
      Map.get(row, column) == value
    end)
  end




end
