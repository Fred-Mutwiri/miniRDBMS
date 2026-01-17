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

  def create(conn, %{"id" => id, "name" => name, "email" => email}) do
    sql = """
    INSERT INTO merchants (id, name, email, active)
    VALUES (#{id}, "#{name}", "#{email}", true)
    """

    case MiniRDBMS.execute(sql) do
      {:ok, _} ->
        json(conn, 201, %{status: "created"})

      {:error, {:duplicate_unique, _}} ->
        json(conn, 409, %{error: "email already exists"})

      {:error, {:duplicate_primary_key}} ->
        json(conn, 409, %{error: "id already exists"})

      {:error, reason} ->
        json(conn, 400, %{error: inspect(reason)})
    end
  end

  def update(conn, id, params) do
    updates =
      params
      |> Enum.map(fn {k, v} -> "#{k} = #{format(v)}" end)
      |> Enum.join(", ")

    sql = "UPDATE merchants SET #{updates} WHERE id = #{id}"

    case MiniRDBMS.execute(sql) do
      {:ok, 0} ->
        json(conn, 404, %{error: "merchant not found"})

      {:ok, _count} ->
        json(conn, 200, %{status: "updated"})

      {:error, reason} ->
        json(conn, 400, %{error: inspect(reason)})
    end
  end

  def delete(conn, id) do
    sql = "DELETE FROM merchants WHERE id = #{id}"

    case MiniRDBMS.execute(sql) do
      {:ok, 0} ->
        json(conn, 404, %{error: "merchant not found"})

      {:ok, _} ->
        send_resp(conn, 204, "")

      {:error, reason} ->
        json(conn, 400, %{error: inspect(reason)})
    end
  end



  defp format(v) when is_binary(v), do: ~s("#{v}")
  defp format(v), do: v

  defp json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
