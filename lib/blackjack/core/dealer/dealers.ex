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

  def build_deck(dealer_name) do
    GenServer.cast(Blackjack.parent(@registry, dealer_name), {:build_deck})
  end

  # def deal_single(dealer_name, player_name) do
  #   GenServer.cast(
  #     Blackjack.parent(@registry, dealer_name),
  #     {:deal_single, dealer_name, player_name}
  #   )
  # end

  def deal_all(dealer_name, table_name) do
    GenServer.cast(
      Blackjack.parent(@registry, dealer_name),
      {:deal_all, dealer_name, table_name}
    )
  end

  # Server

  @impl true
  def init(_) do
    IO.puts("Creating dealer.")

    {:ok, %Dealer{dealer_id: self()}}
  end

  @impl true
  def handle_cast({:build_deck}, dealer) do
    {:noreply, %Dealer{dealer | deck: Deck.build_deck()}}
  end

  # @impl true
  # def handle_cast({:deal_single, _dealer_name, player_name}, dealer) do
  #   %Dealer{deck: deck} = dealer
  #   {card, _rest_of_deck} = deck |> Enum.split(1)

  #   # IO.puts("+++TABLE+++")
  #   # Tables.list_players(table_name)
  #   # IO.puts("++++++")
  #   {:noreply, dealer}
  # end

  @impl true
  def handle_cast({:deal_all, _dealer_name, table_name}, %Dealer{deck: deck} = dealer) do
    {card, rest_of_deck} = deck |> Enum.split(1)

    updated_players =
      table_name
      |> Tables.list_players()
      |> Enum.map(fn player ->
        [{pid, _}] = Registry.lookup(@registry, player)

        Players.update_player(
          player,
          Map.update!(%Player{user_pid: pid}, :hand, fn previous ->
            [card | previous]
          end)
        )
      end)

    IO.inspect(updated_players)

    {:noreply, %Dealer{dealer | deck: rest_of_deck}}
  end
end
