defmodule Blackjack.Core.Server do
  use DynamicSupervisor

  alias Blackjack.Core.Tables

  @registry Registry.Core

  def start_link(server_name) do
    DynamicSupervisor.start_link(__MODULE__, :ok,
      name: Blackjack.via_tuple(@registry, server_name)
    )
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_table(server_name, table_name) do
    IO.puts("Creating table '#{table_name}' on server '#{server_name}'.")

    child_spec = {Tables, table_name}

    Blackjack.parent(@registry, server_name)
    |> DynamicSupervisor.start_child(child_spec)
  end

  def remove_table(server_name, table_name) do
    [{table_id, _}] = Registry.lookup(@registry, table_name)

    Blackjack.parent(@registry, server_name)
    |> DynamicSupervisor.terminate_child(table_id)
  end

  def list_tables_by_pid(server_name) do
    Task.async_stream(
      children(server_name),
      fn {_, pid, _, _} ->
        pid
      end,
      ordered: true
    )
    |> Enum.to_list()
    |> Keyword.get_values(:ok)
  end

  def list_tables_by_name(server_name) do
    Enum.map(list_tables_by_pid(server_name), fn pid ->
      Registry.keys(@registry, pid) |> Enum.at(0) |> IO.puts()
    end)
  end

  def children(server_name) do
    Blackjack.parent(@registry, server_name)
    |> DynamicSupervisor.which_children()
  end

  def count_children(server_name) do
    Blackjack.parent(@registry, server_name)
    |> DynamicSupervisor.count_children()
  end
end
