defmodule BlackjackCLI.Views.Dashboard do
  import Ratatouille.View

  def update(model, msg), do: model

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "ACTIONS" do
              if model.input == 0 do
                label(content: "Account", background: :white, color: :black)
              else
                label(content: "Account")
              end

              if model.input == 1 do
                label(content: "Servers", background: :white, color: :black)
              else
                label(content: "Servers")
              end

              if model.input == 2 do
                label(content: "Search", background: :white, color: :black)
              else
                label(content: "Search")
              end
            end
          end
        end
      end
    end
  end

  defp screens do
    {:account, :servers, :search}
  end

  defp match_screen(index) do
    Enum.find(screens |> Tuple.to_list(), fn screen ->
      screens |> elem(index) == screen
    end)
  end
end
