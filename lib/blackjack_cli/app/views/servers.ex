defmodule BlackjackCLI.Views.Servers do
  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command
  alias Blackjack.Core

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  @spec update(any, any) :: any
  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        switch_menus(model)

      {:event, %{ch: ?w}} ->
        update_cmd(%{model | input: max(model.input - 1, 0), data: model.data})

      {:event, %{key: @down}} ->
        if Map.has_key?(model, :menu) and model.menu == true do
          %{model | input: model.input + 1}
        else
          update_cmd(%{
            model
            | input: min(model.input + 1, length(model.data) - 1)
          })
        end

      {:event, %{ch: ?s}} ->
        update_cmd(%{
          model
          | input: min(model.input + 1, length(model.data) - 1)
        })

      {:event, %{key: @up}} ->
        if Map.has_key?(model, :menu) and model.menu == true do
          %{model | input: model.input - 1}
        else
          update_cmd(%{model | input: max(model.input - 1, 0), data: model.data})
        end

      {:event, %{key: @enter}} ->
        if Map.has_key?(model, :menu) == false or model.menu == false do
          %{"server_name" => server_name} = match_servers(model.data, model.input)

          Core.join_server(model.user.username, server_name)

          %{
            model
            | screen: :server,
              input: server_name,
              data:
                :httpc.request(
                  "http://localhost:4000/server/#{server_name |> Blackjack.format_name()}"
                )
          }
        else
          case match_menu(model) do
            :menu ->
              %{model | screen: match_menu(model), input: 0}

            _ ->
              %{model | screen: match_menu(model), input: ""}
          end
        end

      _ ->
        model
    end
  end

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "Servers", height: 10 do
              viewport offset_y: scroll(model) do
                Enum.with_index(
                  model.data,
                  fn %{"server_name" => server_name}, index ->
                    if model.input == index and
                         (Map.has_key?(model, :menu) == false or
                            (Map.has_key?(model, :menu) == true and model.menu == false)) do
                      label(
                        content: "#{server_name}",
                        background: :white,
                        color: :black
                      )
                    else
                      label(content: "#{server_name}")
                    end
                  end
                )
              end
            end
          end

          column size: 8 do
            panel title: "Server Info", height: 10 do
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
            end
          end
        end

        row do
          column size: 12 do
            panel title: "ACTIONS", height: 8 do
              if model.input == 0 and Map.has_key?(model, :menu) and model.menu == true do
                label(content: "Create Server", background: :white, color: :black)
              else
                label(content: "Create Server")
              end

              if model.input == 1 and Map.has_key?(model, :menu) and model.menu == true do
                label(content: "Find Server", background: :white, color: :black)
              else
                label(content: "Find Server")
              end

              if model.input == 2 and Map.has_key?(model, :menu) and model.menu == true do
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

  defp match_menu(model) do
    [:create_server, :find_server, :menu]
    |> Enum.at(model.input)
  end

  defp match_servers(servers, index) do
    servers
    |> Enum.find(fn server ->
      servers |> Enum.at(index) == server
    end)
  end

  defp update_cmd(model) do
    list_servers =
      if Enum.count(model.data) > 0 do
        {:ok, {_, _, list_servers}} = :httpc.request('http://localhost:4000/servers')
        list_servers |> Jason.decode!()
      else
        []
      end

    Command.new(fn -> list_servers end, :servers_updated)

    model
  end

  defp scroll(model) do
    if Map.has_key?(model, :menu) == false or model.menu == false do
      model.input
    else
      0
    end
  end

  def switch_menus(model) do
    if Map.has_key?(model, :menu) == false or model.menu == false do
      %{model | input: 0}
      |> Map.put(:menu, true)
    else
      Map.put(model, :menu, false)
    end
  end
end
