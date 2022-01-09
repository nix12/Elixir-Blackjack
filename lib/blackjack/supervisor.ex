defmodule Blackjack.Supervisor do
  use Supervisor

  def start_link(_arg) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    children = [
      {Blackjack.Accounts.AccountsRegistry, []},
      {Blackjack.Core.CoreRegistry, []},
      {Blackjack.Accounts.Supervisor, []},
      {Blackjack.Core.Supervisor, []},
      {Blackjack.NodeObserver, []},
      {Task.Supervisor, name: Blackjack.TaskSupervisor},
      {Cachex, name: Blackjack.Cache},
      %{
        id: Task,
        start: {Task, :start, [&Blackjack.Core.Servers.start_all_servers/0]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
