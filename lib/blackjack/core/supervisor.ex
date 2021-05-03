defmodule Blackjack.Core.Supervisor do
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
    IO.puts("Starting Core DynamicSupervisor.")

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def list_servers do
    Repo.all(Server) |> IO.inspect(label: "SERVERS")
  end

  def create_server(server_name) do
    IO.puts("Creating Server.")

    child_spec = {Servers, server_name}

    Blackjack.lookup(@registry, __MODULE__)
    |> DynamicSupervisor.start_child(child_spec)
  end

  def remove_server(server_name) do
    Blackjack.lookup(@registry, __MODULE__)
    |> DynamicSupervisor.terminate_child(server_name)
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
      Blackjack.lookup(@registry, pid) |> Atom.to_string()
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
