defmodule BlackjackCLI.Views.Exit do
  def update(_, _), do: Application.stop(:blackjack)
end
