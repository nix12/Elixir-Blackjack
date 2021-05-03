defmodule Blackjack.Application do
  use Application

  # Application

  @impl true
  def start(_type, _args) do
    IO.puts("Starting Blackjack application.")

    children = [
      {Blackjack.Repo, []},
      {Plug.Cowboy,
       scheme: :http,
       plug: BlackjackWeb.Router,
       options: [port: Application.get_env(:blackjack, :port), dispatch: dispatch()]},
      {Registry, keys: :unique, name: Registry.Accounts},
      {Registry, keys: :unique, name: Registry.Core},
      {Registry, keys: :unique, name: Registry.Web},
      {PubSub, name: PubSub},
      {Blackjack.Cache, name: Blackjack.Cache},
      {Blackjack.Accounts.Supervisor, name: Blackjack.Accounts.Supervisor},
      {Blackjack.Core.Supervisor, name: Blackjack.Core.Supervisor},
      {Registry, keys: :unique, name: Registry.Client},
      BlackjackWeb.Client
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/", BlackjackWeb.Sockets.AuthenticationHandler, []},
         {"/ws/[...]", BlackjackWeb.Sockets.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {BlackjackWeb.Router, []}}
       ]}
    ]
  end
end
