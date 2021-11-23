defmodule BlackjackCLI.Views.CreateServer do
  import Ratatouille.View

  alias BlackjackCLI.Views.CreateServer.State

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        row do
          column size: 12 do
            panel title: "SERVER NAME" do
              label do
                text(content: model.input)
                text(content: "W", background: :white, color: :white)
              end
            end
          end
        end
      end
    end
  end
end
