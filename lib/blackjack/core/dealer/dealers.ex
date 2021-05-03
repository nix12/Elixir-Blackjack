defmodule Blackjack.Core.Dealers do
  use GenServer

  alias Blackjack.Core.{Dealer, Deck, Tables, Player, Players}

  @registry Registry.Core

  # Client

  def start_link(table_name) do
    GenServer.start_link(
      __MODULE__,
      :ok,
      name: Blackjack.via_tuple(@registry, "#{table_name} dealer")
    )
  end

  def build_deck(table_name) do
    GenServer.cast(Blackjack.lookup(@registry, "#{table_name} dealer"), {:build_deck})
  end

  def initialize_hands(table_name) do
    Enum.each(1..2, fn _ ->
      deal_self(table_name)
      deal_all(table_name)
    end)
  end

  def deal_single(table_name, player_name) do
    GenServer.cast(
      Blackjack.lookup(@registry, "#{table_name} dealer"),
      {:deal_single, "#{table_name} dealer", player_name}
    )
  end

  def deal_all(table_name) do
    GenServer.cast(
      Blackjack.lookup(@registry, "#{table_name} dealer"),
      {:deal_all, "#{table_name} dealer", table_name}
    )
  end

  def deal_self(table_name) do
    GenServer.cast(
      Blackjack.lookup(@registry, "#{table_name} dealer"),
      {:deal_self}
    )
  end

  def get_state(pid) do
    GenServer.call(pid, {:get_state})
  end

  # Server

  @impl true
  def init(_) do
    IO.puts("Creating dealer.")

    {:ok, %Dealer{dealer_pid: self()}}
  end

  @impl true
  def handle_call({:get_state}, _from, player) do
    {:reply, player, player}
  end

  @impl true
  def handle_cast({:deal_single, _dealer_name, player_name}, %Dealer{deck: deck} = dealer) do
    {:noreply, %Dealer{dealer | deck: assign_hand([player_name], deck)}}
  end

  @impl true
  def handle_cast({:build_deck}, dealer) do
    {:noreply, %Dealer{dealer | deck: Deck.build_deck()}}
  end

  @impl true
  def handle_cast({:deal_all, _dealer_name, table_name}, %Dealer{deck: deck} = dealer) do
    {:noreply,
     %Dealer{dealer | deck: table_name |> Tables.list_players_by_name() |> assign_hand(deck)}}
  end

  @impl true
  def handle_cast({:deal_self}, %Dealer{deck: deck} = dealer) do
    {card, rest_of_deck} = deck |> Enum.split(1)

    {:noreply, %Dealer{dealer | deck: rest_of_deck, hand: List.flatten([card | dealer.hand])}}
  end

  defp assign_hand([player_name | remaining_players], deck) do
    {card, rest_of_deck} = deck |> Enum.split(1)

    Players.update_player(
      player_name,
      Map.update!(
        %Player{user_pid: Blackjack.lookup(@registry, player_name)},
        :hand,
        fn previous ->
          [card | previous] |> List.flatten()
        end
      )
    )

    assign_hand(remaining_players, rest_of_deck)
  end

  defp assign_hand(_players, deck), do: deck
end
