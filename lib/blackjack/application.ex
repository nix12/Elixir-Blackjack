defmodule Blackjack.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Node.start(:"blackjack_server_#{Node.list() |> Enum.count()}", :shortnames)

    children = [
      # Node Cluster
      {Cluster.Supervisor,
       [Application.get_env(:libcluster, :topologies), [name: Blackjack.ClusterSupervisor]]},

      # Storage
      {Blackjack.Repo, []},

      # Network
      {Registry, keys: :duplicate, name: Registry.Sockets},
      {Plug.Cowboy,
       scheme: :http,
       plug: BlackjackWeb.Router,
       options: [
         port: port(),
         dispatch: dispatch()
       ]},

      # Cache
      {Cachex, name: Blackjack.Cache},

      # Horde
      {Blackjack.Accounts.AccountsRegistry, []},
      {Blackjack.Core.CoreRegistry, []},
      {Blackjack.Accounts.Supervisor, []},
      {Blackjack.Core.Supervisor, []},
      {Blackjack.NodeObserver, []},

      # Notifications
      Blackjack.Notifier.AccountsNotifier,
      Blackjack.Notifier.CoreNotifier,

      # Startup Tasks
      {Task.Supervisor, name: Blackjack.TaskSupervisor},
      %{
        id: Task,
        start: {Task, :start, [&start_all_servers/0]}
      }
    ]

    opts = [strategy: :one_for_one, name: Blackjack.Supervisor]
    Supervisor.start_link(children, opts)
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
         {"/socket/server/[...]", BlackjackWeb.Sockets.ServerHandler, []},
         #  {"/game/[...]", Blackjack.Sockets.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {BlackjackWeb.Router, []}}
       ]}
    ]
  end

  def start_all_servers do
    if Mix.env() != :test do
      Stream.each(
        Blackjack.Repo.all(Blackjack.Core.ServerQuery.query_servers()),
        &Blackjack.Core.Supervisor.start_server(&1)
      )
      |> Enum.to_list()
    end
  end
end
