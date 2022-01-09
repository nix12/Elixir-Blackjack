defmodule Blackjack.Application do
  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor,
       [Application.get_env(:libcluster, :topologies), [name: Blackjack.ClusterSupervisor]]},
      {Blackjack.Repo, []},
      {Plug.Cowboy,
       scheme: :http,
       plug: BlackjackCLI.Router,
       options: [
         port: Application.get_env(:blackjack, :port),
         dispatch: dispatch()
       ]},
      {Blackjack.Supervisor, []},
      {PubSub, name: Blackjack.Pubsub},
      {Registry, keys: :unique, name: Registry.Web},
      {Registry, keys: :unique, name: Registry.App},
      {Ratatouille.Runtime.Supervisor,
       runtime: [app: BlackjackCLI.App, interval: 100, quit_events: [{:key, 0x1B}]]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp dispatch do
    [
      {:_,
       [
         #  {"/", BlackjackCLI.Sockets.AuthenticationHandler, []},
         {"/game/[...]", BlackjackCLI.Sockets.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {BlackjackCLI.Router, []}}
       ]}
    ]
  end
end
