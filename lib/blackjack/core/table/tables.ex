defmodule Blackjack.Core.Tables do
  use GenServer

  alias Blackjack.Accounts
  alias Blackjack.Core.{Table, Players, Dealers}

  @registry Registry.Core

  # client

  def start_link(table_name) do
    GenServer.start_link(__MODULE__, :ok, name: Blackjack.via_tuple(@registry, table_name))
  end

  def generate_player(table_name) do
    GenServer.call(table_name |> table_id(), {:generate_player}, 30000)
  end

  def generate_players(table_name) do
    GenServer.call(table_name |> table_id(), {:generate_players}, 30000)
  end

  def generate_dealer(table_name) do
    GenServer.call(table_name |> table_id(), {:generate_dealer, table_name}, 30000)
  end

  def list_players(table_name) do
    GenServer.call(table_name |> table_id(), {:list_players})
  end

  # server

  @impl true
  def init(:ok) do
    # Spawn a Dealer here
    {:ok, %Table{}}
  end

  @impl true
  def handle_call({:generate_player}, _from, table) do
    updated_table =
      table
      |> Map.from_struct()
      |> Enum.reduce_while(nil, fn {player, nil_pid} = user, _acc ->
        player_name = IO.gets("Enter player name.\n") |> String.trim()

        {:ok, pid} =
          Accounts.get_user!(player_name)
          |> Players.start()

        if nil_pid == nil do
          {:halt, Map.put(user, player, pid)}
        end
      end)

    {:reply, updated_table, updated_table}
  end

  @impl true
  def handle_call({:generate_players}, _from, table) do
    updated_table = assign_users(table, [1, 2, 3, 4])

    {:reply, updated_table, updated_table}
  end

  @impl true
  def handle_call({:generate_dealer, table_name}, _from, table) do
    {:ok, pid} = Dealers.start_link(table_name)

    updated_table = %{table | ("dealer" |> String.to_existing_atom()) => pid}

    {:reply, updated_table, updated_table}
  end

  @impl true
  def handle_call({:list_players}, _from, table) do
    {_dealer, players} = Map.pop!(table, :dealer)

    player_names =
      players
      |> Map.from_struct()
      |> Enum.map(fn {_player, pid} ->
        Registry.keys(@registry, pid) |> Enum.at(0)
      end)

    {:reply, player_names, table}
  end

  defp table_id(table_name) do
    [{pid, _}] = Registry.lookup(@registry, table_name)
    pid
  end

  defp assign_users(state, [player | remaining_players]) do
    player_name = IO.gets("Enter player name.\n") |> String.trim()

    {:ok, pid} =
      Accounts.get_user!(player_name)
      |> Players.start()

    assign_users(
      %{state | ("player_#{player}" |> String.to_existing_atom()) => pid},
      remaining_players
    )
  end

  defp assign_users(state, players) when players == [], do: state
end
