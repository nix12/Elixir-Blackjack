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
       plug: BlackjackCli.Router,
       options: [
         port: port(),
         dispatch: dispatch()
       ]},
      {Blackjack.Supervisor, []},
      {PubSub, name: Blackjack.Pubsub},
      {Registry, keys: :unique, name: Registry.App}
    ]

    children =
      if Mix.env() != :test do
        [gui() | children]
      else
        children
      end

    opts = [strategy: :one_for_one, name: Main]
    Supervisor.start_link(children, opts)
  end

  defp gui do
    {Ratatouille.Runtime.Supervisor,
     runtime: [app: BlackjackCli.App, interval: 100, quit_events: [{:key, 0x1B}]]}
  end

  defp port do
    if Mix.env() == :test do
      4000
    else
      Application.get_env(:blackjack, :port)
    end
  end

  defp dispatch do
    [
      {:_,
       [
         #  {"/", BlackjackCli.Sockets.AuthenticationHandler, []},
         {"/game/[...]", BlackjackCli.Sockets.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {BlackjackCli.Router, []}}
       ]}
    ]
  end
end
