defmodule MiniRDBMSWeb.MerchantHandler do
  @moduledoc """
  HTTP handlers for merchant resources.

  Responsibilities:
  - translate HTTP requests into SQL
  - call MiniRDBMS public API
  - shape HTTP responses

  No persistence logic lives here.
  """

  import Plug.Conn

  def list(conn) do
    case MiniRDBMS.execute("SELECT * FROM merchants") do
      {:ok, rows} ->
        json(conn, 200, rows)

      {:error, reason} ->
        json(conn, 500, %{error: inspect(reason)})
    end
  end

  def get(conn, id) do
    sql = "SELECT * FROM merchants WHERE id = #{id}"

    case MiniRDBMS.execute(sql) do
      {:ok, []} ->
        json(conn, 404, %{error: "merchant not found"})

      {:ok, [row]} ->
        json(conn, 200, row)

      {:error, reason} ->
        json(conn, 500, %{error: inspect(reason)})
    end
  end

  defp json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
