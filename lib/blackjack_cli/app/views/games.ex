defmodule BlackjackCLI.Views.Games do
  import Ratatouille.View

  def update(model, msg), do: model

  def render(model) do
    view do
      panel title: "BLACKJACK" do
      end
    end
  end
end
