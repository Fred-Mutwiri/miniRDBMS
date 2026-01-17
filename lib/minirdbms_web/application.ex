defmodule MiniRDBMSWeb.Application do
  @moduledoc """
  OTP application entry point for the MiniRDBMS web interface.

  Responsibilities:
  - start the HTTP server
  - ensure the database application is running

  This application is a *client* of MiniRDBMS.
  It does not access internal database modules directly.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Ensure the database is started before accepting requests
    MiniRDBMS.start()
    MiniRDBMSWeb.Bootstrap.init_domain!()

    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: MiniRDBMSWeb.Router,
       options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: MiniRDBMSWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
