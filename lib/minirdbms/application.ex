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
      MiniRDBMS.Catalog,
      {Task, fn -> MiniRDBMS.Bootstrap.start() end},
      MiniRDBMSWeb.Application
    ]

    opts = [strategy: :one_for_one, name: Minirdbms.Supervisor]
    Supervisor.start_link(children, opts)


  end
end
