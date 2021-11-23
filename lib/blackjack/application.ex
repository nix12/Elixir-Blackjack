defmodule Blackjack.Application do
  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    # topologies = Application.get_env(:libcluster, :topologies)

    children = [
      {Cluster.Supervisor, [topologies(), [name: Blackjack.ClusterSupervisor]]},
      # {Blackjack.Supervisor, []},
      {Blackjack.Starter, [self()]},
      {Registry, keys: :unique, name: Registry.Web},
      {Registry, keys: :unique, name: Registry.App},
      {Ratatouille.Runtime.Supervisor,
       runtime: [app: BlackjackCLI.App, interval: 100, quit_events: [{:key, 0x1B}]]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp topologies do
    [blackjack: [strategy: Cluster.Strategy.Gossip]]
  end
end
