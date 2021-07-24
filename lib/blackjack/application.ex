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
       scheme: :http,
       plug: BlackjackCLI.Router,
       options: [port: Application.get_env(:blackjack, :port), dispatch: dispatch()]},
      {Registry, keys: :unique, name: Registry.Accounts},
      {Registry, keys: :unique, name: Registry.Core},
      {Registry, keys: :unique, name: Registry.Web},
      {PubSub, name: PubSub},
      {Cachex, name: Blackjack.Cache},
      {Blackjack.Accounts.Supervisor, name: Blackjack.Accounts.Supervisor},
      {Blackjack.Core.Supervisor, name: Blackjack.Core.Supervisor},
      {Registry, keys: :unique, name: Registry.App},
      # {Ratatouille.Runtime.Supervisor, runtime: [app: BlackjackCLI.App]},
      %{
        id: Task,
        start: {Task, :start_link, [&Blackjack.Core.Servers.start_all/0]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/", BlackjackCLI.Sockets.AuthenticationHandler, []},
         {"/ws/[...]", BlackjackCLI.Sockets.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {BlackjackCLI.Router, []}}
       ]}
    ]
  end
end
