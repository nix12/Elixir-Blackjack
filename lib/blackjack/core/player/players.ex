defmodule Blackjack.Core.Players do
  use GenServer

  alias Blackjack.Core.Player

  @registry Registry.Core

  # Client

  def start({_user_pid, user_info} = player) do
    GenServer.start(__MODULE__, player, name: Blackjack.via_tuple(@registry, user_info.username))
  end

  def get_player(player_name) do
    GenServer.call(Blackjack.parent(@registry, player_name), {:get_player, player_name})
  end

  def update_player(player_name, player_info) do
    GenServer.call(Blackjack.parent(@registry, player_name), {:update_player, player_info})
  end

  def join_table(table, player) do
    GenServer.call(__MODULE__, {:join_table, table, player})
  end

  # Server

  # Setup through top level api file
  @impl true
  def init({user_pid, player_info}) do
    IO.puts("Creating Player.")

    Process.monitor(user_pid)
    Registry.register_name({@registry, player_info.username}, self())

    {:ok, %Player{user_pid: self()}}
  end

  @impl true
  def handle_call({:get_player, player_name}, _from, player) do
    {:reply, Map.get(player, player_name), player}
  end

  @impl true
  def handle_call({:update_player, player_info}, _from, player) do
    updated_player = %Player{
      player
      | hand: player_info.hand,
        total: player_info.total,
        active: player_info.active
    }

    {:reply, updated_player, updated_player}
  end

  @impl true
  def handle_call({:join_table, table, player}, _from, state) do
    [{_, players}] =
      _updated_state =
      Enum.map(state, fn {_server, tables} ->
        Map.get_and_update(tables, table, fn value ->
          {value, [player]}
        end)
      end)

    {:reply, players, state}
  end

  @impl true
  def terminate(reason, state) do
    IO.puts("TERMINTATED")
    IO.inspect(reason)
    IO.inspect(state)
  end
end
