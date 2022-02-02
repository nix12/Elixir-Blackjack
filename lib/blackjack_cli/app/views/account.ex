defmodule BlackjackCli.Views.Account do
  import Ratatouille.View

  def update(model, msg), do: model

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        label(content: "ACCOUNT")
      end
    end
  end
end
