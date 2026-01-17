defmodule MiniRDBMS.Storage do
  @moduledoc """
  Persistence layer for MiniRDBMS table state.

  This module is responsible for *durability only*.
  It knows how to save and load opaque table state to disk.

  Design decisions:
  - One file per table
  - Full state serialization on every write
  - Erlang term serialization (term_to_binary)

  Explicit non-goals:
  - Transactions
  - Partial writes
  - Concurrency control
  - Cross-table consistency

  This is intentional and documented.
  """

  @storage_dir "data"

  @doc """
  Persist a table's state to disk.

  Overwrites any existing state for the table.
  """
  def save(table_name, state) when is_atom(table_name) do
    ensure_storage_dir!()

    table_name
    |> table_path()
    |> File.write!(:erlang.term_to_binary(state))

    :ok
  end

  @doc """
  Load a table's persisted state from disk.

  Returns:
    {:ok, state} if found
    {:error, :not_found} otherwise
  """
  def load(table_name) when is_atom(table_name) do
    path = table_path(table_name)

    if File.exists?(path) do
      {:ok, path |> File.read!() |> :erlang.binary_to_term()}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Remove persisted state for a table.

  Intended for DROP TABLE or test cleanup.
  """
  def delete(table_name) when is_atom(table_name) do
    path = table_path(table_name)

    if File.exists?(path), do: File.rm!(path)
    :ok
  end

  defp table_path(table_name) do
    Path.join(@storage_dir, "#{table_name}.db")
  end

  # defp ensure_storage_dir! do
  #   File.mkdir_p!(@storage_dir)
  # end

  @doc """
    Ensure the storage directory exists.
    This is safe to call multiple times.
  """
  def ensure_storage_dir! do
    File.mkdir_p!(@storage_dir)
  end
end
