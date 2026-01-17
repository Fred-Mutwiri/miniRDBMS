defmodule MiniRDBMSWeb.Router do
  @moduledoc """
  HTTP router for the MiniRDBMS web interface.

  Responsibilities:
  - route HTTP requests to handlers
  - apply common plugs (JSON parsing, response headers)

  This module does *not*:
  - construct SQL
  - access the database
  - implement business rules
  """

  use Plug.Router

  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :dispatch

  get "/health" do
    send_resp(conn, 200, "ok")
  end

  # Domain routes will be added incrementally.
  # Example (not implemented yet):
  #
  # POST   /merchants
  # GET    /merchants
  # GET    /merchants/:id
  # PUT    /merchants/:id
  # DELETE /merchants/:id

  get "/merchants" do
    MiniRDBMSWeb.MerchantHandler.list(conn)
  end

  get "/merchants/:id" do
    MiniRDBMSWeb.MerchantHandler.get(conn, id)
  end
  match _ do
    send_resp(conn, 404, "not found")
  end
end
