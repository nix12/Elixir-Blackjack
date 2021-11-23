defmodule Blackjack.Core.Supervisor do
  require Logger

  use DynamicSupervisor

  alias Blackjack.Core.Servers

  # Client

  def start_link(_ \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Server

  @impl true
  def init(_) do
    Logger.info("Starting Core Supervisor.")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_child(any) :: :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def start_child(server_options) do
    child_spec = %{
      id: Servers,
      start: {Servers, :start_link, [server_options]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def register({_options, server_name, _username} = server_options) do
    case Swarm.whereis_or_register_name(server_name, __MODULE__, :start_child, [server_options]) do
      {:ok, pid} ->
        Swarm.join(:servers, pid)

      {:error, term} ->
        Logger.info("ERROR JOINING SWARM: #{inspect(term)}")
    end
  end
end
