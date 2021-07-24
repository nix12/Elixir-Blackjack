defmodule BlackjackCLI.Views.Servers do
  require Logger

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command
  alias Blackjack.Core
  alias BlackjackCLI.Controllers.ServersController

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  def update(model, msg) do
    {:ok, {_, _, list_servers}} = model.data
    list_servers = list_servers |> Jason.decode!()

    case msg do
      {:event, %{ch: ?w}} ->
        %{model | input: model.input - 1}

      {:event, %{key: @down}} ->
        updated_model = %{
          model
          | input: min(model.input + 1, length(list_servers) - 1)
        }

        update_cmd(updated_model)

      {:event, %{ch: ?s}} ->
        %{model | input: model.input + 1}

      {:event, %{key: @up}} ->
        updated_model = %{model | input: max(model.input - 1, 0), data: list_servers}

        update_cmd(updated_model)

      {:event, %{key: @enter}} ->
        if Map.has_key?(model, :menu) == false or model.menu == false do
          %{"server_name" => server_name} = match_servers(list_servers, model.input)

          Logger.info(
            inspect(~c(http://localhost:4000/server/#{server_name |> Blackjack.format_name()}))
          )

          Core.join_server(
            model.user.username,
            server_name
          )

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

      {:event, %{key: @tab}} ->
        if Map.has_key?(model, :menu) == false or model.menu == false do
          %{model | input: 0}
          |> Map.put(:menu, true)
        else
          Map.put(model, :menu, false)
        end

      _ ->
        model
    end
  end

  def render(model) do
    {:ok, {_, _, list_servers}} = model.data
    list_servers = list_servers |> Jason.decode!()

    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "Servers", height: 10 do
              viewport offset_y: scroll(model) do
                Enum.with_index(
                  list_servers,
                  fn %{"server_name" => server_name}, idx ->
                    if model.input == idx and
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
                list_servers,
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
    {:ok, {_, _, list_servers}} = :httpc.request('http://localhost:4000/servers')
    list_servers = list_servers |> Jason.decode!()

    Command.new(
      fn ->
        list_servers
      end,
      :servers_updated
    )

    model
  end

  def scroll(model) do
    if Map.has_key?(model, :menu) == false or model.menu == false do
      model.input
    else
      0
    end
  end
end
