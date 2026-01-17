defmodule MiniRDBMSWeb.Application do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    MiniRDBMS.start()
    MiniRDBMSWeb.Bootstrap.init_domain!()

    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: MiniRDBMSWeb.Router,
       options: [port: 4000]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
