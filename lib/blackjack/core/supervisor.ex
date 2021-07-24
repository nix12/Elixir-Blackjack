defmodule Blackjack.Core.Supervisor do
  require Logger

  use DynamicSupervisor

  alias Blackjack.Repo
  alias Blackjack.Core.{Servers, Server}

  @registry Registry.Core

  # Client

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: Blackjack.via_tuple(@registry, __MODULE__))
  end

  # Server

  @impl true
  def init(_) do
    Logger.info("Starting Core Supervisor.")

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def list_servers_by_pid do
    Task.async_stream(
      children(),
      fn {_, pid, _, _} ->
        pid
      end,
      ordered: true
    )
    |> Enum.to_list()
    |> Keyword.get_values(:ok)
  end

  def list_servers_by_name do
    Enum.map(list_servers_by_pid(), fn pid ->
      Blackjack.unformat_name(Blackjack.name(@registry, pid))
    end)
  end

  def children do
    Blackjack.lookup(@registry, __MODULE__)
    |> DynamicSupervisor.which_children()
  end

  def count_children do
    Blackjack.lookup(@registry, __MODULE__)
    |> DynamicSupervisor.count_children()
  end
end
