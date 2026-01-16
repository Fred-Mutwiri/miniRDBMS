defmodule MiniRDBMS.REPL do
  @moduledoc """
  Interactive Read–Eval–Print Loop (REPL) for MiniRDBMS.
    - this is an Interactive shell for executing SQL-like commands.
  Responsibilities:
  - read SQL-like commands from standard input
  - pass commands to the public MiniRDBMS API
  - print results or errors

  Design principles:
  - the REPL is a thin client
  - it does not parse SQL
  - it does not touch table processes directly

  Limitations (intentional):
  - single-line statements only
  - no command history

  ## Interactive REPL
  MiniRDBMS includes an interactive SQL-like shell.
  Start it with:

  ```bash
  iex -S mix

  Then run:
  MiniRDBMS.REPL.start()

  """

  @prompt "minirdbms> "

  @doc """
  Starts the interactive REPL loop.

  This function blocks the current process and reads
  input until the user exits.
  """
  def start do
    IO.puts("miniRDBMS interactive shell")
    IO.puts("type SQL statements or 'exit' to quit...")
    loop()
  end

  defp loop do
    case IO.gets(@prompt) do
      nil ->
        :ok

      input ->
        input
        |> String.trim()
        |> handle_input()

        loop()
    end
  end

  defp handle_input(""), do: :ok

  defp handle_input("exit"), do: exit(:normal)
  defp handle_input("quit"), do: exit(:normal)

  defp handle_input(sql) do
    case MiniRDBMS.execute(sql) do
      {:ok, result} -> print_result(result)
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
  end

  defp print_result(result) when is_list(result) do
    Enum.each(result, &IO.inspect/1)
  end

  defp print_result(result) do
    IO.inspect(result)
  end



 end
