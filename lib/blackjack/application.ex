defmodule Blackjack.Application do
  alias Blackjack.{Player, Card}

  def main([player | other_players] = players, deck, state) when players != [] do
    if player.active do
      [active_player | rest_of_deck] = turn(player, deck)

      main(other_players, rest_of_deck, [active_player | state])
    else
      IO.puts("END OF GAME")
    end
  end

  def main(_players, deck, state) do
    if state != [] do
      end_of_turn =
        state
        |> List.flatten()
        |> Enum.reverse()
        |> total_cards
        |> return_players
        |> Enum.reject(&(!&1.active))
        |> IO.inspect()
        |> reset_player_totals

      main(end_of_turn, deck, [])
    else
      IO.puts("NO ACTIVE PLAYERS")
    end
  end

  def turn(player, deck) do
    action =
      IO.gets("Would your like to hit or stay\n")
      |> String.trim_trailing()

    case action do
      "hit" ->
        hit(player, deck, 1, [])

      "stay" ->
        stay(player, deck, [])
    end
  end

  def set_players, do: get_player_count() |> create_players

  def deal([player | other_players] = players, deck, hand_size, state) when players != [] do
    {cards, rest_of_deck} = Enum.split(deck, hand_size)

    deal(
      other_players,
      rest_of_deck,
      hand_size,
      [%Player{player | hand: List.flatten([cards | player.hand])} | state]
    )
  end

  def deal(_player, deck, _hand_size, state), do: [Enum.reverse(state) | deck]

  def hit(player, deck, hand_size, state) do
    {cards, rest_of_deck} = Enum.split(deck, hand_size)

    [[%Player{player | hand: List.flatten([cards | player.hand])} | state] | rest_of_deck]
  end

  def stay(player, deck, state), do: [[player | state] | deck]

  def get_player_count do
    # IO.puts("How many will be playing?\n")

    # receive do
    #   num ->
    #     case num do
    #       num when num <= 4 and num > 0 ->
    #         IO.puts("The #{num} players will be play this game")
    #         num

    #       _ ->
    #         IO.puts("something about the number of players")
    #         get_player_count()
    #     end
    # end

    num =
      IO.gets("How many will be playing?\n")
      |> String.trim_trailing()
      |> String.to_integer()

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

      %Player{name: String.trim(name)}
    end)
  end

  def total_cards(players) do
    Enum.map(players, fn %Player{hand: hand, total: total} = player ->
      Enum.map_reduce(Enum.reverse(hand), total, fn %Card{value: [value | one]} = card, acc ->
        calculation = if(is_ace?(card) && acc > 21, do: List.first(one), else: value) + acc

        case acc do
          acc when acc <= 21 ->
            {%Player{player | total: calculation}, calculation}

          acc when acc > 21 ->
            {%Player{player | total: calculation, active: false}, calculation}
        end
      end)
    end)
  end

  def return_players(players), do: for({hands, _acc} <- players, do: List.last(hands))

  def reset_player_totals(players), do: for(player <- players, do: %Player{player | total: 0})

  def is_ace?(card), do: String.contains?(card.symbol, "A")
end
