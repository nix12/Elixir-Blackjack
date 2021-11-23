# Controls turn mechanics and player assignment.
defmodule Blackjack.Core.Tables do
  use GenServer

  alias Blackjack.Core.{Players, Dealers}

  @registry Registry.Core

  defmacro is_alive(pid) do
    {_block, _meta, args} =
      quote do
        Process.alive?(unquote(pid))
      end

    IO.inspect(args, label: "ARGS")
  end

  # client

  def start_link(table_name) do
    GenServer.start_link(__MODULE__, table_name, name: Blackjack.via_tuple(@registry, table_name))
  end

  def generate_dealer(table_name) do
    GenServer.call(Blackjack.lookup(@registry, table_name), {:generate_dealer, table_name})
  end

  def list_players_by_pid(table_name) do
    GenServer.call(Blackjack.lookup(@registry, table_name), {:list_players_by_pid})
  end

  def list_players_by_name(table_name) do
    GenServer.call(Blackjack.lookup(@registry, table_name), {:list_players_by_name})
  end

  def get_table(table_name) do
    GenServer.call(Blackjack.lookup(@registry, table_name), {:get_table})
  end

  def update_table(table_name, table_data) do
    GenServer.call(Blackjack.lookup(@registry, table_name), {:update_table, table_data})
  end

  def turn(table_name) do
    GenServer.call(Blackjack.lookup(@registry, table_name), {:turn})
  end

  def check_activities(table_name) do
    GenServer.cast(Blackjack.lookup(@registry, table_name), {:check_activities})
  end

  # server

  @impl true
  def init(table_name) do
    {:ok, table_name}
  end

  @impl true
  def handle_call({:generate_dealer, table_name}, _from, table) do
    {:ok, pid} = Dealers.start_link(table_name)
    updated_table = List.insert_at(table, -1, pid)

    {:reply, updated_table, updated_table}
  end

  @impl true
  def handle_call({:list_players_by_pid}, _from, table) do
    {:reply, table, table}
  end

  @impl true
  def handle_call({:list_players_by_name}, _from, table) do
    player_names =
      Enum.map(table, fn pid ->
        Registry.keys(@registry, pid) |> Enum.at(0)
      end)

    {:reply, player_names, table}
  end

  @impl true
  def handle_call({:get_table}, _from, table) do
    {:reply, table, table}
  end

  @impl true
  def handle_call({:update_table, table_data}, _from, _table) do
    {:reply, table_data, table_data}
  end

  @impl true
  def handle_call({:turn}, _from, table) do
    for pid <- table |> List.delete(List.last(table)) do
      IO.inspect(pid, label: "PID")
      send(pid, {:player_action, "Would you like to hit or stand?\n", self()})
    end

    {:reply, table, table}
  end

  @impl true
  def handle_cast({:check_activities}, table) do
    seated_table = Enum.zip(0..3, table)

    Enum.each(seated_table, fn {seat, pid} ->
      IO.inspect("#{seat}: #{get_state(pid).active}")
    end)

    {:noreply, table}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, object, _reason}, table) do
    updated_table =
      Enum.reduce(table, [], fn pid, acc ->
        if pid == object, do: List.delete(table, pid), else: [pid | acc]
      end)

    {:noreply, updated_table}
  end

  @impl true
  def handle_info({:table_action, action, player_pid}, table) do
    # case action do
    #   :hit ->
    #     send(
    #       player_pid,
    #       {:hit, Blackjack.name(@registry, self()), Blackjack.name(@registry, player_pid)}
    #     )

    #   :stand ->
    #     PubSub.publish(
    #       Registry.keys(@registry, self()) |> Enum.at(0),
    #       {:stand, Registry.keys(@registry, self()) |> Enum.at(0),
    #        Registry.keys(@registry, player_pid) |> Enum.at(0)}
    #     )

    #   nil ->
    #     IO.puts("SOMETHING WENT WRONG")
    # end

    {:noreply, table}
  end

  @impl true
  def terminate(_reason, table) do
    IO.puts("Table crashed")
  end

  defp get_state(pid) do
    case is_struct(Dealers.get_state(pid), Dealer) do
      true ->
        Dealers.get_state(pid)

      _ ->
        Players.get_state(pid)
    end
  end
end
