defmodule Blackjack.Application do
  alias Blackjack.{Player, Card}

  def main do
    IO.puts("MAIN SELF")
    IO.inspect(self())

    # Task.start_link(__MODULE__, :take_turn, [])

    # Task.await(turn, :infinity)
    take_turn()
    check_for_active_players()
  end

  def setup do
    setup_players()
    setup_deck()
    assign_hand()
  end

  def setup_players do
    players = get_player_count() |> create_players()
    IO.puts("PLAYER PROCESS")
    IO.inspect(players)

    Enum.map(players, fn player ->
      Process.info(player)
      IO.puts("")
    end)

    Agent.start_link(fn -> players end, name: :players_process)
  end

  def get_players do
    Agent.get(:players_process, fn players -> players end)
  end

  def setup_deck do
    deck = Blackjack.Deck.build_deck()
    Agent.start_link(fn -> deck end, name: :deck_process)
  end

  def get_player_count do
    # num =
    #   IO.gets("How many will be playing?\n")
    #   |> String.trim_trailing()
    #   |> String.to_integer()

    # case num do
    #   num when num <= 4 and num > 0 ->
    #     IO.puts("The #{num} players will be play this game")
    #     num

    #   _ ->
    #     IO.puts("Please enter a number between 1 and 4")
    #     get_player_count()
    # end

    IO.puts("How many will be playing?\n")

    receive do
      {:player_count, count} ->
        if count <= 4 && count > 0 do
          IO.puts("The #{count} players will be play this game")
          count
        else
          IO.puts("Please enter a number between 1 and 4")
          get_player_count()
        end
    end
  end

  def create_players(player_count) do
    Enum.map(1..player_count, fn count ->
      # name = IO.gets("What is player #{count} name.\n") |> String.trim()
      # IO.puts("NAME")
      # IO.inspect(name)
      # %Player{name: name}

      IO.puts("What is player #{count} name.\n")

      receive do
        {:player_name, name} ->
          {:ok, player} =
            Agent.start(
              fn ->
                %Player{name: name}
              end,
              name: "player#{count}" |> String.to_atom()
            )

          player
      end
    end)
  end

  def deal(num) do
    deck = Agent.get(:deck_process, fn cards -> cards end)
    {cards, rest_of_deck} = Enum.split(deck, num)
    Agent.update(:deck_process, fn _cards -> rest_of_deck end)
    cards
  end

  def assign_hand do
    Agent.get(:players_process, fn players ->
      Enum.map(players, fn player ->
        Agent.update(player, fn player ->
          %Player{player | hand: List.flatten([deal(2) | player.hand])}
        end)
      end)
    end)
  end

  def hit(player) do
    Agent.update(
      :players_process,
      fn players ->
        Enum.map(players, fn p ->
          if match?(^p, player) do
            %Player{p | hand: List.flatten([deal(1) | p.hand])}
          else
            p
          end
        end)
      end,
      :infinity
    )
  end

  def stand(player) do
    Agent.update(
      :players_process,
      fn players ->
        Enum.map(players, fn p ->
          if match?(^p, player) do
            %Player{p | hand: List.flatten([deal(0) | p.hand])}
          else
            p
          end
        end)
      end,
      :infinity
    )
  end

  def get_action(player) do
    # action = IO.gets("Would you like to hit or stand?\n") |> String.trim_trailing()

    # case action do
    #   "hit" ->
    #     hit(player)

    #   "stand" ->
    #     stand(player)

    #   _ ->
    #     IO.puts("Not an action, please enter 'hit' or 'stand'.\n")
    #     get_action(player)
    # end

    IO.puts("Would you like to hit or stand?\n")

    receive do
      {:player_action, player_name, "hit"} ->
        Agent.get(player_name, fn f ->
          hit(f)
        end)

      {:player_action, player_name, "stand"} ->
        Agent.get(player_name, fn f ->
          stand(f)
        end)

      _ ->
        IO.puts("Not an action, please enter 'hit' or 'stand'.\n")
    end

    get_action(player)
  end

  def take_turn() do
    Agent.get(
      :players_process,
      fn players ->
        IO.puts("PLAYERS")
        IO.inspect(players)

        Enum.each(players, fn player ->
          IO.puts("PLAYER")
          IO.inspect(player)

          # IO.inspect(Agent.get(player, fn player -> player end))

          Agent.update(
            player,
            fn player ->
              case player.active do
                true ->
                  get_action(player)
                  total_cards()
                  return_players()
                  IO.inspect(get_players())

                false ->
                  IO.puts("NEXT ROUND")
                  :take_turn
              end
            end,
            :infinity
          )

          reset_player_totals()
        end)
      end,
      :infinity
    )
  end

  def check_for_active_players do
    parent = self()

    if Enum.any?(get_players(), & &1.active) do
      send(parent, :continue)
    else
      send(parent, :end)
    end
  end

  def total_cards do
    Agent.update(:players_process, fn players ->
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
    end)
  end

  def return_players do
    Agent.update(:players_process, fn players ->
      for({hands, _acc} <- players, do: List.last(hands))
    end)
  end

  def reset_player_totals do
    Agent.update(:players_process, fn players ->
      for(player <- players, do: %Player{player | total: 0})
    end)
  end

  def is_ace?(card), do: String.contains?(card.symbol, "A")
end
