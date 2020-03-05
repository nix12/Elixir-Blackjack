defmodule Blackjack.Gameplay do
  alias Blackjack.{Player, Deck}

  def start_game do
    Deck.build_deck()
    |> deal(2)
  end

  def set_players do
    get_player_count()
    |> create_players
  end

  # def deal(deck, hand_size, players) do
  #   Enum.map(players, fn player ->
  #     %Player{player | hand: cards}
  #   end)
  # end

  def deal(deck, hand_size) do
    # {cards, _rest_of_deck} = Enum.split(deck, hand_size)
    # cards
    hand =
      deck
      |> Enum.split(hand_size)
      |> Tuple.to_list()
      |> List.pop_at(0)

    IO.inspect(hand)
    hand
  end

  def get_player_count do
    num_of_players = IO.gets("How will be playing?\n")
    num = String.to_integer(String.trim_trailing(num_of_players))

    case num do
      num when num <= 4 and num > 0 ->
        IO.puts("The #{num} players will be play this game")
        num

      _ ->
        IO.puts("something about the number of players")
        get_player_count()
    end
  end

  def create_players(player_count) do
    Enum.map(1..player_count, fn count ->
      name = IO.gets("What is player #{count} name.\n")
      %Player{name: name}
    end)
  end
end
