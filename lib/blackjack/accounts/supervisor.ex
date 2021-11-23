defmodule Blackjack.Accounts.Supervisor do
  require Logger

  use DynamicSupervisor

  alias Blackjack.Accounts.Users

  def start_link(_ \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    Logger.info("Starting Accounts Supervisor.")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(user) do
    Logger.info("USER: #{inspect(user)}")

    child_spec = %{
      id: Users,
      start: {Users, :start_link, [user]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def register(user) do
    Logger.info("REGISTER: #{inspect(user)}")
    {:ok, pid} = Swarm.register_name(user.username, __MODULE__, :start_child, [user])
    Logger.info("USER SWARM PID: #{inspect(pid)}")
    Swarm.join(:accounts, pid)
  end
end
