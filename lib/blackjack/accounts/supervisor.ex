defmodule Blackjack.Accounts.Supervisor do
  use Supervisor

  def start_link(_) do
    IO.puts("Starting Accounts Supervisor")
    Supervisor.start_link(__MODULE__, :ok, name: :user_supervisor)
  end

  def init(:ok) do
    children = [
      {Registry, keys: :unique, name: Registry.Accounts},
      {Blackjack.Accounts.Server, name: Blackjack.Accounts.Server}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
