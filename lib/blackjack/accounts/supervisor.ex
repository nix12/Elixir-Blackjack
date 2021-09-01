defmodule Blackjack.Accounts.Supervisor do
  require Logger

  use DynamicSupervisor

  @registry Registry.Accounts

  def start_link(_ \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: Blackjack.via_tuple(@registry, __MODULE__))
  end

  def init(_) do
    Logger.info("Starting Accounts Server.")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
