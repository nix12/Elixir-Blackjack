defmodule Blackjack.Application do
  require Logger

  use Application

  # Application

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Blackjack application.")

    children = [
      {Blackjack.Repo, []},
      {Plug.Cowboy,
       scheme: :http, plug: BlackjackCLI.Router, options: [port: 4000, dispatch: dispatch()]},
      {Registry, keys: :unique, name: Registry.Accounts},
      {Registry, keys: :unique, name: Registry.Core},
      {Registry, keys: :unique, name: Registry.Web},
      {PubSub, name: PubSub},
      {Cachex, name: Blackjack.Cache},
      {Blackjack.Accounts.Supervisor, name: Blackjack.Accounts.Supervisor},
      {Blackjack.Core.Supervisor, name: Blackjack.Core.Supervisor},
      {Task.Supervisor, name: Blackjack.TaskSupervisor},
      {Registry, keys: :unique, name: Registry.App},
      # {Ratatouille.Runtime.Supervisor,
      #  runtime: [app: BlackjackCLI.App, quit_events: [{:key, 0x1B}]]},
      %{
        id: Task,
        start: {Task, :start, [&Blackjack.Core.Servers.start_all_servers/0]}
      }
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
