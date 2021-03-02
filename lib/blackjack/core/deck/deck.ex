defmodule Blackjack.Core.Deck do
  @moduledoc """
    Methods for creating a deck and standard gameplay actions.
  """

  alias Blackjack.Core.Deck.Card

  @doc """
    Builds the deck to make it ready for game play.
  """
  def build_deck do
    create_cards()
    |> assign_values
    |> build_and_assign_aces
    |> combine
    |> shuffle
  end

  @doc """
    Creates a deck of 48 playing cards (DOES NOT HAVE ACES).
    The cards are stored as structs holding values for suit
    and symbol.
  """
  def create_cards do
    symbols = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    suits = ["\u2660", "\u2665", "\u2666", "\u2663"]

    for symbol <- symbols, suit <- suits do
      %Card{suit: suit, symbol: symbol}
    end
  end

  @doc """
    Takes a deck and assigns values to the cards based on
    if they are regular or special cards. This is done
    by spliting the deck into chunks of 4 to assign values.
  """
  def assign_values(deck) do
    deck = Enum.chunk_every(deck, 4)

    for {chunk, index} <- Enum.with_index(deck, 2) do
      for item <- chunk do
        if index <= 10 do
          %Card{item | value: [index]}
        else
          %Card{item | value: [10]}
        end
      end
    end
  end

  @doc """
    Builds the aces with to values then adds then to
    a deck.
  """
  def build_and_assign_aces(deck) do
    symbols = ["A"]
    suits = ["\u2660", "\u2665", "\u2666", "\u2663"]

    aces =
      for symbol <- symbols, suit <- suits do
        %Card{suit: suit, symbol: symbol, value: [11, 1]}
      end

    [aces | deck]
  end

  @doc """
    Takes the chunked deck and flattens it back out into
    a single deck.
  """
  def combine(deck), do: List.flatten(deck)

  @doc """
    Shuffles the deck.
  """
  def shuffle(deck), do: Enum.shuffle(deck)
end
