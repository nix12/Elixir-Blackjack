defmodule BlackjackCLI.Views.Servers do
  require Logger

  import Ratatouille.View

  alias BlackjackCLI.Views.Servers.State

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "SERVERS", height: 10 do
              viewport offset_y: scroll(model) do
                if model.menu == false do
                  model.data
                  |> Enum.slice(
                    max(model.input - length(model.data), 0),
                    min(model.input + 7, length(model.data))
                  )
                  |> Enum.with_index(fn %{"server_name" => server_name}, index ->
                    if model.input == index do
                      label(
                        content: "#{server_name}",
                        background: :white,
                        color: :black
                      )
                    else
                      label(content: "#{server_name}")
                    end
                  end)
                else
                  model.data
                  |> Enum.slice(0, 7)
                  |> Enum.map(fn %{"server_name" => server_name} ->
                    label(content: "#{server_name}")
                  end)
                end
              end
            end
          end

          column size: 8 do
            panel title: "SERVER INFO", height: 10 do
              # if model.menu == false do
              Enum.with_index(
                model.data,
                fn %{
                     "server_name" => server_name,
                     "player_count" => player_count,
                     "table_count" => table_count
                   },
                   index ->
                  if model.input == index do
                    [
                      label(content: "server_name: #{server_name}"),
                      label(content: "player_count: #{player_count}"),
                      label(content: "table_count: #{table_count}")
                    ]
                  end
                end
              )

              # else
              #   Enum.with_index(
              #     model.data,
              #     fn %{
              #          "server_name" => server_name,
              #          "player_count" => player_count,
              #          "table_count" => table_count
              #        },
              #        index ->
              #       if 0 == index do
              #         [
              #           label(content: "server_name: #{server_name}"),
              #           label(content: "player_count: #{player_count}"),
              #           label(content: "table_count: #{table_count}")
              #         ]
              #       end
              #     end
              #   )
              # end
            end
          end
        end

        row do
          column size: 12 do
            panel title: "ACTIONS", height: 8 do
              if model.input == 0 and model.menu == true do
                label(content: "Create Server", background: :white, color: :black)
              else
                label(content: "Create Server")
              end

              if model.input == 1 and model.menu == true do
                label(content: "Find Server", background: :white, color: :black)
              else
                label(content: "Find Server")
              end

              if model.input == 2 and model.menu == true do
                label(content: "Main Menu", background: :white, color: :black)
              else
                label(content: "Main Menu")
              end
            end
          end
        end
      end
    end
  end

  defp scroll(model) do
    if model.menu == false do
      model.input
    end
  end
end
