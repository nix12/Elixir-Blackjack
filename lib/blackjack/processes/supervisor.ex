defmodule Blackjack.Processes.Supervisor do
  use Supervisor

  def start_link(opts) do
    IO.puts("Supervisor started.")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Blackjack.Repo, []},
      {Plug.Cowboy,
       scheme: :http, plug: Blackjack.Network.Router, options: [dispatch: dispatch()]},
      {Registry, keys: :duplicate, name: Registry.Blackjack},
      {Blackjack.Processes.Server, name: Blackjack.Processes.Server}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws/[...]", Blackjack.Sockets.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Blackjack.Network.Router, []}}
       ]}
    ]
  end
end
