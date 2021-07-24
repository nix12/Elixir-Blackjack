defmodule Blackjack.Accounts.Supervisor do
  require Logger

  use Supervisor

  def start_link(_) do
    Logger.info("Starting Accounts Supervisor")
    Supervisor.start_link(__MODULE__, :ok, name: :user_supervisor)
  end

  def init(:ok) do
    children = [
      {Blackjack.Accounts.Server, name: Blackjack.Accounts.Server}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
