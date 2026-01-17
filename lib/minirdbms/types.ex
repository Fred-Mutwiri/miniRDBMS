defmodule MiniRDBMS.Types do
  @moduledoc """
    Defines supported column types and casting rules.
    Supported types:
    - :int
    - :text
    - :bool

    This module is pure and stateless.
  """

  @type column_type :: :int | :text | :bool

  @doc """
    Casts a value to the given column type.
    Returns:
      {:ok, cast_value}
      {:error, :invalid_type}
  """
  def cast(:int, value) when is_integer(value), do: {:ok, value}
  def cast(:int, value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_type}
    end
  end

  def cast(:text, value) when is_binary(value), do: {:ok, value}
  def cast(:text, value), do: {:ok, to_string(value)}

  def cast(:bool, true), do: {:ok, true}
  def cast(:bool, false), do: {:ok, false}
  def cast(:bool, "true"), do: {:ok, true}
  def cast(:bool, "false"), do: {:ok, false}
  def cast(:bool, _), do: {:error, :invalid_type}

  def cast(_, _), do: {:error, :unknown_type}
end
