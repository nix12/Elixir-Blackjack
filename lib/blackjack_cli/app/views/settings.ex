defmodule BlackjackCLI.Views.Settings do
  import Ratatouille.View

  def update(model, msg), do: model

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        label(content: "Settings")
      end
    end
  end
end
