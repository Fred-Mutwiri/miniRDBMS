defmodule MiniRDBMS.Application do
  @moduledoc """
  OTP application entry point for MiniRDBMS.

  Responsible for bootstrapping the database system and
  supervising long-lived components such as:

  - the catalog (metadata)
  - table supervisors
  - optional REPL process

  At this stage, supervision structure is intentionally minimal.
  """

  use Application

  @impl true
  def start(_type, _args) do

    children = [
      {Registry, keys: :unique, name: MiniRDBMS.TableRegistry},

      # Core DB
      MiniRDBMS.Catalog,

       # Persistence bootstrap
      Supervisor.child_spec(
        {Task, fn -> MiniRDBMS.Bootstrap.start() end},
        id: :storage_bootstrap
      ),

      # Web domain bootstrap
      Supervisor.child_spec(
        {Task, fn -> MiniRDBMSWeb.Bootstrap.init_domain!() end},
        id: :web_domain_bootstrap
      ),

      # HTTP server
      {Plug.Cowboy,
       scheme: :http,
       plug: MiniRDBMSWeb.Router,
       options: [port: 4000]}

    ]

    opts = [strategy: :one_for_one, name: Minirdbms.Supervisor]
    Supervisor.start_link(children, opts)


  end
end
