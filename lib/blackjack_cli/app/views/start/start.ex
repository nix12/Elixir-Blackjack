defmodule BlackjackCLI.Views.Start do
  @moduledoc """
    Shows the start menu for the blackjack application
  """
  import Ratatouille.View

  alias BlackjackCLI.Views.Start.State

  def update(model, msg), do: State.update(model, msg)

  @doc """
    Renders start menu
  """
  def render(model) do
    view do
      panel title: "BLACKJACK" do
        if model.input == 0 do
          label(content: "1) Login", background: :white, color: :black)
        else
          label(content: "1) Login")
        end

        if model.input == 1 do
          label(content: "2) Register", background: :white, color: :black)
        else
          label(content: "2) Register")
        end

        if model.input == 2 do
          label(content: "3) Exit", background: :white, color: :black)
        else
          label(content: "3) Exit")
        end
      end
    end
  end
end
