defmodule BlackjackCli.Views.Menu do
  import Ratatouille.View

  alias BlackjackCli.Views.Menu.State

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        if model.input == 0 do
          label(content: "1) Servers", background: :white, color: :black)
        else
          label(content: "1) Servers")
        end

        if model.input == 1 do
          label(content: "2) Search", background: :white, color: :black)
        else
          label(content: "2) Search")
        end

        if model.input == 2 do
          label(content: "3) Account", background: :white, color: :black)
        else
          label(content: "3) Account")
        end

        if model.input == 3 do
          label(content: "4) Settings", background: :white, color: :black)
        else
          label(content: "4) Settings")
        end

        if model.input == 4 do
          label(content: "5) Exit", background: :white, color: :black)
        else
          label(content: "5) Exit")
        end
      end
    end
  end
end
