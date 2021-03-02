defmodule Blackjack.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    IO.puts("Starting Blackjack Supervisor.")

    children = [
      {Blackjack.Repo, []},
      {Plug.Cowboy, scheme: :http, plug: Blackjack.Router, options: [dispatch: dispatch()]},
      {Registry, keys: :unique, name: Registry.Core},
      {Blackjack.Accounts.Supervisor, name: Blackjack.Accounts.Supervisor},
      {Blackjack.Core.Supervisor, name: Blackjack.Core.Supervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws/[...]", Blackjack.Sockets.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Blackjack.Router, []}}
       ]}
    ]
  end
end
