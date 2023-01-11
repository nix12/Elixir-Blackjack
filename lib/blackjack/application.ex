defmodule Blackjack.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
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
         dispatch: dispatch(),
         protocol_options: [request_timeout: :timer.minutes(5)],
         transport_options: [
           num_acceptors: 10
         ]
       ]},

      # Cache
      {Cachex, name: Blackjack.Cache},

      # Web
      {Registry, keys: :unique, name: BlackjackWeb.Registry},

      # Horde
      {Blackjack.Accounts.AccountsRegistry, []},
      {Blackjack.Core.CoreRegistry, []},
      {Blackjack.Accounts.Supervisor, []},
      {Blackjack.Core.Supervisor, []},
      {Blackjack.NodeObserver, []},

      # Notifiers
      Blackjack.Notifiers.AccountsNotifier,
      Blackjack.Notifiers.CoreNotifier,

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
         {"/socket/user/[...]", BlackjackWeb.Sockets.UserHandler, []},
         {:_, Plug.Cowboy.Handler, {BlackjackWeb.Router, []}}
       ]}
    ]
  end

  defp start_all_servers do
    if Mix.env() != :test do
      Stream.each(
        Blackjack.Repo.all(Blackjack.Core.ServerQuery.query_servers()),
        &Blackjack.Core.Supervisor.start_server(&1)
      )
      |> Enum.to_list()
    end
  end
end
