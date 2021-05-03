defmodule Blackjack.Core.Dealer do
  defstruct deck: nil, hand: [], total: 0, active: true, dealer_pid: nil
end
