defmodule Blackjack.Supervisor do
  use Supervisor

  def start_link(_arg) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    children = [
      {Blackjack.Repo, []},
      {Plug.Cowboy,
       scheme: :http,
       plug: BlackjackCLI.Router,
       options: [port: Application.get_env(:blackjack, :port), dispatch: dispatch()]},
      {Blackjack.Core.Supervisor, []},
      {Blackjack.Accounts.Supervisor, []},
      {Task.Supervisor, name: Blackjack.TaskSupervisor},
      {Cachex, name: Blackjack.Cache},
      %{
        id: Task,
        start: {Task, :start, [&Blackjack.Core.Servers.start_all_servers/0]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # def start_child(opts) do
  #   child_spec = %{
  #     id: :"app_#{randstring(10)}",
  #     start: {__MODULE__, :start_link, [opts]},
  #     restart: :transient
  #   }

  #   Supervisor.start_child(__MODULE__, child_spec)
  # end

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
