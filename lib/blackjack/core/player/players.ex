defmodule Blackjack.Core.Players do
  use GenServer

  alias Blackjack.Core.{Player, Card, Dealers, Tables}

  @registry Registry.Core

  # Client

  def start({_user_pid, user_info} = player) do
    GenServer.start(__MODULE__, player, name: Blackjack.via_tuple(@registry, user_info.username))
  end

  def get_player(player_name) do
    GenServer.call(Blackjack.lookup(@registry, player_name), {:get_player})
  end

  def get_state(pid) do
    GenServer.call(pid, {:get_state})
  end

  def update_player(player_name, player_info) do
    IO.puts("UPDATE PLAYER CALLED")

    GenServer.call(
      Blackjack.lookup(@registry, player_name),
      {:update_player, player_info},
      :infinity
    )
    |> IO.inspect(label: "CALL")
  end

  def total_cards(player_name) do
    GenServer.cast(Blackjack.lookup(@registry, player_name), {:total_cards})
  end

  def join_table(table_name, player_name) do
    GenServer.call(
      Blackjack.lookup(@registry, player_name),
      {:join_table, table_name, player_name}
    )
  end

  # Server

  # Setup through top level api file
  @impl true
  def init({user_pid, _player_info}) do
    IO.puts("Creating Player.")

    Process.monitor(user_pid)
    # Registry.register_name({@registry, player_info.username}, self())

    {:ok, %Player{user_pid: self()}}
  end

  @impl true
  def handle_call({:get_player}, _from, player) do
    {:reply, player, player}
  end

  @impl true
  def handle_call({:get_state}, _from, player) do
    {:reply, player, player}
  end

  @impl true
  def handle_call({:join_table, table_name, player_name}, _from, player) do
    if check_table?(table_name) do
      Tables.update_table(
        table_name,
        add_user_to_table(table_name)
      )

      PubSub.subscribe(Blackjack.lookup(@registry, player_name), table_name)
      PubSub.publish(table_name, {:join_message, table_name, player_name})
    else
      IO.inspect({:error, "Table is full or does not exist."})
    end

    {:reply, player, player}
  end

  @impl true
  def handle_call({:update_player, player_info}, from, player) do
    updated_player = %Player{
      player
      | hand: List.flatten([player_info.hand | player.hand]),
        total: player_info.total,
        active: player_info.active
    }

    {:reply, updated_player.hand, updated_player}
  end

  @impl true
  def handle_cast({:total_cards}, player) do
    total =
      Enum.reduce(player.hand, 0, fn %Card{value: [value | one]} = card, acc ->
        if is_ace?(card) || acc > 21, do: List.last(one) + acc, else: value + acc
      end)

    {:noreply, check_total(player, total)}
  end

  @impl true
  def handle_info({:player_action, msg, table_pid}, player) do
    action = IO.gets(self(), msg) |> String.trim() |> String.to_atom()
    send(table_pid, {:table_action, action, self()})

    {:noreply, player}
  end

  @impl true
  def handle_info({:hit, table_name, player_name}, player) do
    IO.puts("HITTING")
    PubSub.publish(table_name, {:message, "#{player_name} hits."})
    Dealers.deal_single(table_name, player_name)

    {:noreply, player}
  end

  @impl true
  def handle_info({:stand, _table_name, player_name}, player) do
    IO.puts("#{player_name} stands.")

    {:noreply, player}
  end

  @impl true
  def handle_info({:join_message, table_name, player_name}, player) do
    IO.puts("#{player_name} joined the '#{table_name}' table.")

    {:noreply, player}
  end

  @impl true
  def handle_info({:message, message}, player) do
    IO.puts(message)

    {:noreply, player}
  end

  @impl true
  def handle_info(something, player) do
    IO.inspect(something, label: "SOMETHING")
    IO.inspect(player, label: "CATCH ALL")
    {:noreply, player}
  end

  @impl true
  def terminate(reason, state) do
    IO.puts("TERMINTATED")

    IO.inspect(reason)
    IO.inspect(state)
  end

  defp is_ace?(card), do: String.contains?(card.symbol, "A")

  defp check_total(player, total) do
    case total do
      total when total <= 21 ->
        %Player{player | total: total}

      total when total > 21 ->
        %Player{player | total: total, active: false}
    end
  end

  defp check_table?(table_name) do
    len =
      table_name
      |> Tables.list_players_by_pid()
      |> length()

    if len <= 100 do
      true
    else
      false
    end
  end

  defp add_user_to_table(table_name) do
    table = Tables.list_players_by_pid(table_name)
    [self() | table]
  end
end
